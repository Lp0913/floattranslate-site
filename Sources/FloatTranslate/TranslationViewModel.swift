import AppKit
import Combine
import Foundation
import Translation

@MainActor
final class TranslationViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case preparing
        case loading
        case slow
        case translated
        case failed(String)
    }

    @Published private(set) var sourceText = ""
    @Published private(set) var queryText = ""
    @Published private(set) var translatedText = ""
    @Published private(set) var definition: FormattedDefinition?
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var needsSourceLanguage = false
    @Published private(set) var presentationSequence = 0
    @Published var targetLanguage: TranslationLanguage = .simplifiedChinese {
        didSet {
            guard targetLanguage != oldValue, !isPreparingInput else { return }
            beginTranslation()
        }
    }
    @Published var sourceLanguage: TranslationLanguage? {
        didSet {
            guard sourceLanguage != oldValue, !isPreparingInput else { return }
            if sourceLanguage != nil {
                sourceRequiresConfirmation = false
            }
            beginTranslation()
        }
    }
    @Published private(set) var configuration: TranslationSession.Configuration?
    let speechService = SpeechService()
    var onNeedsLanguageModelPreparation: (() -> Void)?

    private let settings: AppSettings

    private enum Defaults {
        static let slowResponseNanoseconds: UInt64 = 5_000_000_000
        static let finalTimeoutNanoseconds: UInt64 = 25_000_000_000
    }

    private var generation = 0
    private var inferredSourceLanguage: TranslationLanguage = .english
    private var sourceRequiresConfirmation = false
    private var isPreparingInput = false
    private var translationTimeoutTask: Task<Void, Never>?

    init(settings: AppSettings) {
        self.settings = settings
    }

    var testReport: String {
        let phaseName: String
        switch phase {
        case .idle: phaseName = "idle"
        case .preparing: phaseName = "preparing"
        case .loading: phaseName = "loading"
        case .slow: phaseName = "slow"
        case .translated: phaseName = "translated"
        case let .failed(message): phaseName = "failed: \(message)"
        }
        return [
            "source=\(sourceText)",
            "query=\(queryText)",
            "phase=\(phaseName)",
            "translation=\(translatedText)",
            "phonetics=\(definition?.displayPhonetics ?? "")",
            "definitions=\(definition?.groups.flatMap { $0.senses.map(\.gloss) }.joined(separator: " | ") ?? "")",
            "primary=\(usesDictionaryAsPrimaryResult ? "dictionary" : "translation")",
        ].joined(separator: "\n")
    }

    var usesDictionaryAsPrimaryResult: Bool {
        guard definition != nil,
              (sourceLanguage ?? inferredSourceLanguage) == .english else {
            return false
        }
        let text = queryText.isEmpty ? sourceText : queryText
        return text.split(whereSeparator: \.isWhitespace).count == 1
    }

    var canCopyTranslation: Bool {
        !translatedText.isEmpty && !usesDictionaryAsPrimaryResult
    }

    func translate(text: String) {
        speechService.stop()
        sourceText = text
        queryText = LookupTextNormalizer.normalized(text)
        translatedText = ""
        let resolution = LanguagePolicy.resolveSource(for: queryText)
        inferredSourceLanguage = resolution.suggestedLanguage
        sourceRequiresConfirmation = {
            if case .needsSelection = resolution { return true }
            return false
        }()
        isPreparingInput = true
        sourceLanguage = nil
        targetLanguage = inferredSourceLanguage == .simplifiedChinese ? .english : .simplifiedChinese
        isPreparingInput = false
        beginTranslation()
    }

    func show(error: Error) {
        speechService.stop()
        translationTimeoutTask?.cancel()
        sourceText = ""
        queryText = ""
        translatedText = ""
        definition = nil
        configuration = nil
        needsSourceLanguage = false
        phase = .failed(TranslationErrorMessage.message(for: error))
    }

    func markPresented() {
        presentationSequence += 1
    }

    func retry() {
        beginTranslation()
    }

    func copyTranslation() {
        guard !translatedText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType: .string)
    }

    func toggleSourceSpeech() {
        let language = sourceLanguage ?? inferredSourceLanguage
        speechService.toggle(
            text: sourceText,
            localeIdentifier: speechLocaleIdentifier(for: language),
            target: .source
        )
    }

    func toggleTranslationSpeech() {
        speechService.toggle(
            text: translatedText,
            localeIdentifier: speechLocaleIdentifier(for: targetLanguage),
            target: .translation
        )
    }

    func toggleEnglishPronunciation(_ accent: EnglishAccent) {
        speechService.toggle(
            text: queryText.isEmpty ? sourceText : queryText,
            localeIdentifier: accent.localeIdentifier,
            target: accent == .british ? .britishPronunciation : .americanPronunciation
        )
    }

    private func speechLocaleIdentifier(for language: TranslationLanguage) -> String {
        language == .english ? settings.englishAccent.localeIdentifier : language.speechLocaleIdentifier
    }

    func performTranslation(using session: TranslationSession) async {
        let currentGeneration = generation
        let text = queryText.isEmpty ? sourceText : queryText
        guard !text.isEmpty else { return }

        do {
            let source = sourceLanguage ?? inferredSourceLanguage
            let availability = await LanguageAvailability().status(
                from: source.localeLanguage,
                to: targetLanguage.localeLanguage
            )
            guard currentGeneration == generation else { return }

            switch availability {
            case .installed:
                break
            case .supported:
                phase = .preparing
                onNeedsLanguageModelPreparation?()
                try await Task.sleep(nanoseconds: 150_000_000)
                try await session.prepareTranslation()
                guard currentGeneration == generation else { return }
                phase = .loading
                scheduleTranslationTimeout(for: currentGeneration)
            case .unsupported:
                translationTimeoutTask?.cancel()
                needsSourceLanguage = true
                phase = .failed("当前系统不支持这组语言翻译，请重新选择语言")
                return
            @unknown default:
                translationTimeoutTask?.cancel()
                needsSourceLanguage = true
                phase = .failed("无法确认语言模型状态，请重新选择语言后重试")
                return
            }

            let response = try await session.translate(text)
            guard currentGeneration == generation else { return }
            translationTimeoutTask?.cancel()
            translatedText = response.targetText
            needsSourceLanguage = false
            phase = .translated
        } catch {
            guard currentGeneration == generation else { return }
            translationTimeoutTask?.cancel()
            translatedText = ""
            needsSourceLanguage = true
            if TranslationError.unableToIdentifyLanguage ~= error {
                phase = .failed("无法自动识别原文语言，请手动选择")
            } else {
                phase = .failed("翻译失败，可手动选择原文语言后重试")
            }
        }
    }

    private func beginTranslation() {
        guard !sourceText.isEmpty else { return }
        generation += 1
        translatedText = ""
        translationTimeoutTask?.cancel()

        if sourceLanguage == nil, sourceRequiresConfirmation {
            configuration = nil
            needsSourceLanguage = true
            phase = .failed("无法确定原文语言，请先选择后再翻译")
            refreshDefinition()
            return
        }

        needsSourceLanguage = false
        phase = .loading
        var nextConfiguration = configuration ?? TranslationSession.Configuration()
        nextConfiguration.source = (sourceLanguage ?? inferredSourceLanguage).localeLanguage
        nextConfiguration.target = targetLanguage.localeLanguage
        nextConfiguration.invalidate()
        configuration = nextConfiguration
        scheduleTranslationTimeout(for: generation)

        refreshDefinition()
    }

    private func scheduleTranslationTimeout(for currentGeneration: Int) {
        translationTimeoutTask?.cancel()
        translationTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Defaults.slowResponseNanoseconds)
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self,
                      self.generation == currentGeneration,
                      self.phase == .loading else { return }
                self.phase = .slow
            }

            try? await Task.sleep(nanoseconds: Defaults.finalTimeoutNanoseconds)
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self,
                      self.generation == currentGeneration,
                      self.phase == .slow else { return }
                self.generation += 1
                self.configuration = nil
                self.translatedText = ""
                self.needsSourceLanguage = true
                self.phase = .failed("翻译长时间无响应，请确认语言包已下载后重试")
            }
        }
    }

    private func refreshDefinition() {
        definition = nil
        let text = queryText.isEmpty ? sourceText : queryText
        guard LookupPolicy.isLookupCandidate(text) else { return }
        let source = sourceLanguage ?? inferredSourceLanguage
        let target = targetLanguage
        let currentGeneration = generation
        Task.detached(priority: .userInitiated) {
            let entries = DictionaryService.definitions(for: text, sourceLanguage: source, targetLanguage: target)
            let formatted = entries.isEmpty ? nil : DefinitionFormatter.format(entries: entries)
            await MainActor.run { [weak self] in
                guard let self,
                      self.generation == currentGeneration,
                      (self.queryText.isEmpty ? self.sourceText : self.queryText) == text else { return }
                self.definition = (formatted?.isEmpty == false) ? formatted : nil
            }
        }
    }
}

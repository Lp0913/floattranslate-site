import Foundation
import NaturalLanguage

enum TranslationLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"

    var id: String { rawValue }

    static let selectableCases: [TranslationLanguage] = [.simplifiedChinese, .english]

    var displayName: String {
        switch self {
        case .simplifiedChinese: "简体中文"
        case .english: "英语"
        case .japanese: "日语"
        case .korean: "韩语"
        case .french: "法语"
        case .german: "德语"
        case .spanish: "西班牙语"
        }
    }

    var localeLanguage: Locale.Language {
        Locale.Language(identifier: rawValue)
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .simplifiedChinese: "zh-CN"
        case .english: "en-US"
        case .japanese: "ja-JP"
        case .korean: "ko-KR"
        case .french: "fr-FR"
        case .german: "de-DE"
        case .spanish: "es-ES"
        }
    }
}

enum LanguagePolicy {
    enum SourceResolution: Equatable {
        case automatic(TranslationLanguage)
        case needsSelection(suggested: TranslationLanguage)

        var suggestedLanguage: TranslationLanguage {
            switch self {
            case let .automatic(language), let .needsSelection(language):
                language
            }
        }
    }

    static func resolveSource(for text: String) -> SourceResolution {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let counts = scriptCounts(in: trimmed)
        if counts.chinese > 0 || counts.english > 0 {
            return counts.chinese >= counts.english
                ? .automatic(.simplifiedChinese)
                : .automatic(.english)
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        return resolveSource(hypotheses: recognizer.languageHypotheses(withMaximum: 2))
    }

    static func resolveSource(hypotheses: [NLLanguage: Double]) -> SourceResolution {
        let ranked = hypotheses.sorted { $0.value > $1.value }
        guard let first = ranked.first,
              let language = supportedLanguage(for: first.key) else {
            return .needsSelection(suggested: .english)
        }

        let runnerUpConfidence = ranked.dropFirst().first?.value ?? 0
        let hasEnoughConfidence = first.value >= 0.65
        let hasClearLead = first.value - runnerUpConfidence >= 0.20
        return hasEnoughConfidence && hasClearLead
            ? .automatic(language)
            : .needsSelection(suggested: language)
    }

    static func defaultSource(for text: String) -> TranslationLanguage {
        resolveSource(for: text).suggestedLanguage
    }

    static func containsCJK(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value) ||
            (0x3400...0x4DBF).contains(scalar.value) ||
            (0x3040...0x30FF).contains(scalar.value) ||
            (0xAC00...0xD7AF).contains(scalar.value) ||
            (0xF900...0xFAFF).contains(scalar.value)
        }
    }

    static func scriptCounts(in text: String) -> (chinese: Int, english: Int) {
        var chinese = 0
        var english = 0
        for scalar in text.unicodeScalars {
            if (0x4E00...0x9FFF).contains(scalar.value)
                || (0x3400...0x4DBF).contains(scalar.value)
                || (0xF900...0xFAFF).contains(scalar.value) {
                chinese += 1
            } else if (0x41...0x5A).contains(scalar.value)
                || (0x61...0x7A).contains(scalar.value) {
                english += 1
            }
        }
        return (chinese, english)
    }

    static func defaultSource(dominantLanguage: NLLanguage?) -> TranslationLanguage {
        dominantLanguage.flatMap(supportedLanguage(for:)) ?? .english
    }

    private static func supportedLanguage(for language: NLLanguage) -> TranslationLanguage? {
        switch language {
        case .simplifiedChinese, .traditionalChinese: .simplifiedChinese
        case .english: .english
        default: nil
        }
    }

    static func defaultTarget(for text: String) -> TranslationLanguage {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return defaultTarget(dominantLanguage: recognizer.dominantLanguage)
    }

    static func defaultTarget(dominantLanguage: NLLanguage?) -> TranslationLanguage {
        guard let dominantLanguage else {
            return .simplifiedChinese
        }

        switch dominantLanguage {
        case .simplifiedChinese, .traditionalChinese:
            return .english
        default:
            return .simplifiedChinese
        }
    }
}

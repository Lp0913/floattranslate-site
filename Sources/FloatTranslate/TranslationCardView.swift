import SwiftUI
import Translation

struct TranslationCardView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @ObservedObject private var speechService: SpeechService
    let onClose: () -> Void
    let onSizeChange: (CGSize) -> Void
    @State private var isPresented = false
    @State private var bodyContentHeight: CGFloat = 0
    @State private var didCopy = false
    @State private var showsAllDefinitions = false
    @State private var copyResetTask: Task<Void, Never>?
    private let cardShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

    init(
        viewModel: TranslationViewModel,
        onClose: @escaping () -> Void,
        onSizeChange: @escaping (CGSize) -> Void
    ) {
        self.viewModel = viewModel
        speechService = viewModel.speechService
        self.onClose = onClose
        self.onSizeChange = onSizeChange
    }

    var body: some View {
        card
            .scaleEffect(isPresented ? 1 : 0.96, anchor: .topTrailing)
            .offset(y: isPresented ? 0 : -12)
            .opacity(isPresented ? 1 : 0)
            .padding(TranslationCardLayout.shadowMargin)
            .background(panelSizeReader)
            .onPreferenceChange(CardSizePreferenceKey.self, perform: onSizeChange)
            .onAppear(perform: animatePresentation)
            .onChange(of: viewModel.presentationSequence) { _, _ in
                showsAllDefinitions = false
                animatePresentation()
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: viewModel.phase)
            .translationTask(viewModel.configuration) { session in
                await viewModel.performTranslation(using: session)
            }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 14)

            scrollableBody
                .padding(.bottom, 4)

            footer
        }
        .padding(16)
        .frame(width: TranslationCardLayout.cardWidth)
        .background(cardBackground)
        .clipShape(cardShape)
        .overlay(cardBorder)
        .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
    }

    private var scrollableBody: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                if !viewModel.sourceText.isEmpty {
                    originalText
                        .padding(.bottom, 14)
                }

                translationContent

                if let definition = viewModel.definition {
                    definitionSection(definition)
                        .padding(.top, 14)
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: BodyHeightPreferenceKey.self,
                        value: proxy.size.height
                    )
                }
            )
        }
        .frame(height: clampedBodyHeight)
        .onPreferenceChange(BodyHeightPreferenceKey.self) { height in
            if height > 0 {
                bodyContentHeight = height
            }
        }
    }

    private var clampedBodyHeight: CGFloat {
        min(max(bodyContentHeight, 1), TranslationCardLayout.scrollSectionMaxHeight)
    }

    private var cardBackground: some View {
        cardShape
            .fill(.ultraThinMaterial)
            .overlay {
                cardShape
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.16), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
    }

    private var cardBorder: some View {
        cardShape
            .strokeBorder(.white.opacity(0.34), lineWidth: 1)
    }

    private var panelSizeReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: CardSizePreferenceKey.self, value: proxy.size)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            BrandBubbleIcon()
            Text("FloatTranslate")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.82))
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(.primary.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var originalText: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                SectionLabel(title: "原文", systemImage: "text.quote")
                Spacer()
                speechButton(
                    target: .source,
                    action: viewModel.toggleSourceSpeech,
                    accessibilityLabel: "朗读原文"
                )
            }
            Text(viewModel.sourceText)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            if let phonetics = viewModel.definition?.displayPhonetics {
                HStack(spacing: 7) {
                    Text(phonetics)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.tint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .accessibilityLabel("音标 \(phonetics)")
                    pronunciationButton(.british, target: .britishPronunciation)
                    pronunciationButton(.american, target: .americanPronunciation)
                }
            }
        }
        .padding(11)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func definitionSection(_ definition: FormattedDefinition) -> some View {
        let hiddenSenseCount = definition.groups.reduce(0) { total, group in
            total + max(0, group.senses.count - 3)
        }
        return VStack(alignment: .leading, spacing: 9) {
            SectionLabel(title: "释义", systemImage: "character.book.closed")

            ForEach(Array(definition.groups.enumerated()), id: \.offset) { _, group in
                if !group.senses.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        if let partOfSpeech = DefinitionFormatter.displayPartOfSpeech(group.partOfSpeech) {
                            Text(partOfSpeech)
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(.tint)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.10), in: Capsule())
                        }
                        let visibleSenses = showsAllDefinitions
                            ? group.senses
                            : Array(group.senses.prefix(3))
                        ForEach(Array(visibleSenses.enumerated()), id: \.offset) { index, sense in
                            senseRow(
                                index: index,
                                sense: sense,
                                showUsageLabels: index == 0
                                    || sense.usageLabels != group.senses[index - 1].usageLabels
                            )
                        }
                    }
                }
            }

            if hiddenSenseCount > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showsAllDefinitions.toggle()
                    }
                } label: {
                    Label(
                        showsAllDefinitions
                            ? "收起其他释义"
                            : "展开更多释义（\(hiddenSenseCount)）",
                        systemImage: showsAllDefinitions ? "chevron.up" : "chevron.down"
                    )
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .accessibilityLabel(
                    showsAllDefinitions ? "收起其他释义" : "展开更多释义"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .transition(.opacity)
    }

    private func senseRow(
        index: Int,
        sense: FormattedDefinition.Sense,
        showUsageLabels: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(DefinitionFormatter.circledNumber(index + 1))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                if showUsageLabels, !sense.usageLabels.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(sense.usageLabels, id: \.self) { label in
                            Text(label)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.primary.opacity(0.06), in: Capsule())
                                .help(DefinitionFormatter.usageLabelHelp(label))
                        }
                    }
                }
                Text(sense.gloss)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary.opacity(0.85))
                    .textSelection(.enabled)
                ForEach(Array(sense.examples.enumerated()), id: \.offset) { _, example in
                    Text(example)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var translationContent: some View {
        if viewModel.usesDictionaryAsPrimaryResult {
            EmptyView()
        } else {
            translationPhaseContent
        }
    }

    @ViewBuilder
    private var translationPhaseContent: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()
        case .preparing:
            HStack(alignment: .top, spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                VStack(alignment: .leading, spacing: 3) {
                    Text("正在准备语言模型…")
                        .font(.system(size: 13, weight: .medium))
                    Text("请在系统弹窗中确认下载，完成后会自动翻译")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 54, alignment: .leading)
        case .loading:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("正在翻译…")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 54, alignment: .leading)
        case .slow:
            HStack(alignment: .top, spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                VStack(alignment: .leading, spacing: 3) {
                    Text("翻译响应较慢，仍在处理中…")
                        .font(.system(size: 13, weight: .medium))
                    Text("首次使用该语言时，系统可能正在加载语言模型")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 54, alignment: .leading)
        case .translated:
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    SectionLabel(title: "译文", systemImage: "sparkles")
                    Spacer()
                    speechButton(
                        target: .translation,
                        action: viewModel.toggleTranslationSpeech,
                        accessibilityLabel: "朗读译文"
                    )
                }
                Text(viewModel.translatedText)
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        case let .failed(message):
            VStack(alignment: .leading, spacing: 10) {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                if viewModel.needsSourceLanguage {
                    sourceLanguagePicker
                }
            }
            .frame(minHeight: 54, alignment: .leading)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(TranslationLanguage.selectableCases) { language in
                    Button {
                        viewModel.targetLanguage = language
                    } label: {
                        if language == viewModel.targetLanguage {
                            Label(language.displayName, systemImage: "checkmark")
                        } else {
                            Text(language.displayName)
                        }
                    }
                }
            } label: {
                Label(viewModel.targetLanguage.displayName, systemImage: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.primary.opacity(0.055), in: Capsule())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Spacer()

            if case .translated = viewModel.phase, viewModel.canCopyTranslation {
                Button(action: performCopy) {
                    Label(didCopy ? "已复制" : "复制译文", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(didCopy ? Color.green : Color.accentColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            (didCopy ? Color.green : Color.accentColor).opacity(0.14),
                            in: Capsule()
                        )
                        .scaleEffect(didCopy ? 1.06 : 1)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 12)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var sourceLanguagePicker: some View {
        HStack {
            Text("原文语言")
                .font(.system(size: 12))
            Picker(
                "原文语言",
                selection: Binding(
                    get: { viewModel.sourceLanguage },
                    set: { viewModel.sourceLanguage = $0 }
                )
            ) {
                Text("请选择").tag(TranslationLanguage?.none)
                ForEach(TranslationLanguage.selectableCases) { language in
                    Text(language.displayName).tag(Optional(language))
                }
            }
            .labelsHidden()
            .frame(width: 130)

            Button("重试") {
                viewModel.retry()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func animatePresentation() {
        isPresented = false
        copyResetTask?.cancel()
        didCopy = false
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72, blendDuration: 0.08)) {
                isPresented = true
            }
        }
    }

    private func performCopy() {
        viewModel.copyTranslation()
        copyResetTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.58)) {
            didCopy = true
        }
        copyResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                didCopy = false
            }
        }
    }

    private func speechButton(
        target: SpeechTarget,
        action: @escaping () -> Void,
        accessibilityLabel: String
    ) -> some View {
        let isSpeaking = speechService.speakingTarget == target
        return Button(action: action) {
            Image(systemName: isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSpeaking ? Color.red : Color.accentColor)
                .frame(width: 24, height: 24)
                .background(
                    (isSpeaking ? Color.red : Color.accentColor).opacity(0.11),
                    in: Circle()
                )
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .help(isSpeaking ? "停止朗读" : accessibilityLabel)
        .accessibilityLabel(isSpeaking ? "停止朗读" : accessibilityLabel)
    }

    private func pronunciationButton(_ accent: EnglishAccent, target: SpeechTarget) -> some View {
        let isSpeaking = speechService.speakingTarget == target
        return Button {
            viewModel.toggleEnglishPronunciation(accent)
        } label: {
            Label(accent.controlLabel, systemImage: isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(isSpeaking ? Color.red : Color.accentColor)
                .padding(.horizontal, 7)
                .frame(height: 23)
                .background(
                    (isSpeaking ? Color.red : Color.accentColor).opacity(0.11),
                    in: Capsule()
                )
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .fixedSize()
        .help(isSpeaking ? "停止朗读" : "播放\(accent.displayName)")
        .accessibilityLabel(isSpeaking ? "停止朗读" : "播放\(accent.displayName)")
    }
}

private struct BrandBubbleIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 25))
                .foregroundStyle(.tint)
            Text("Lee")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .offset(x: 0.5, y: -1.5)
        }
        .frame(width: 26, height: 22)
        .accessibilityLabel("Lee")
    }
}

private struct SectionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}

private struct CardSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let nextSize = nextValue()
        if nextSize != .zero {
            value = nextSize
        }
    }
}

private struct BodyHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

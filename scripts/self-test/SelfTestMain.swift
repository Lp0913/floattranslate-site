import AppKit
import AVFoundation
import Foundation
import NaturalLanguage

@main
struct SelfTestMain {
    private static var failures: [String] = []

    static func main() {
        check(LookupTextNormalizer.normalized("sourceText") == "source text", "camelCase normalization")
        check(LookupTextNormalizer.normalized("selected_text") == "selected text", "snake_case normalization")
        check(LookupTextNormalizer.normalized("Open") == "Open", "plain word preservation")
        check(LookupTextNormalizer.normalized("Windows and Mac") == "Windows and Mac", "sentence preservation")
        check(LookupTextNormalizer.normalized("可以提炼") == "可以提炼", "Chinese preservation")

        check(LanguagePolicy.resolveSource(for: "on tour") == .automatic(.english), "short English phrase")
        check(LanguagePolicy.defaultSource(for: "可以提炼") == .simplifiedChinese, "Chinese source detection")
        check(LanguagePolicy.defaultTarget(dominantLanguage: .simplifiedChinese) == .english, "Chinese target policy")
        check(TranslationLanguage.selectableCases == [.simplifiedChinese, .english], "Chinese-English only")
        check(LanguagePolicy.resolveSource(for: "AI 工具测试") == .automatic(.simplifiedChinese), "mixed text Chinese direction")
        check(LanguagePolicy.resolveSource(for: "Open 中文") == .automatic(.english), "mixed text English direction")
        check(LanguagePolicy.resolveSource(for: "123 --") == .needsSelection(suggested: .english), "non-language selection")

        check(
            DefinitionFormatter.displayPhonetics("BrE ˈsɔːs, AmE sɔrs") == "英音 /ˈsɔːs/ · 美音 /sɔrs/",
            "phonetic labels"
        )
        check(DefinitionFormatter.displayPartOfSpeech("noun") == "名词", "explicit part of speech")
        check(DefinitionFormatter.displayPartOfSpeech("") == nil, "no inferred part of speech")
        check(DefinitionFormatter.circledIndex("㉑") == 21, "circled number 21 parsed")
        check(DefinitionFormatter.circledNumber(21) == "㉑", "circled number 21 displayed")

        let current = DefinitionFormatter.format(
            "current | BrE ˈkʌrənt, AmE ˈkərənt | A. adjective ① (present) 当前的 dāngqián de ▸ the current year 本年度 B. noun ① 电流 diànliú"
        )
        check(current.groups.count == 2, "dictionary groups parsed")
        check(current.groups.first?.partOfSpeech == "adjective", "part of speech parsed")
        check(current.groups.first?.senses.first?.examples == ["the current year 本年度"], "examples parsed")

        check(DictionaryService.recordMatchesQuery("run | BrE rʌn | definition", query: "run"), "matching dictionary headword")
        check(!DictionaryService.recordMatchesQuery("闰（閏） | definition", query: "run"), "unrelated Chinese headword filtered")
        check(LookupPolicy.isLookupCandidate("on tour"), "short phrase lookup")
        check(!LookupPolicy.isLookupCandidate("the quick brown fox"), "sentence lookup exclusion")
        check((try? TextValidator.validate("  hello \n")) == "hello", "selection trimming")
        check(TranslationCardLayout.panelSize(forMeasuredContentHeight: 900).height == 560, "panel max height")

        check(AVSpeechSynthesisVoice(language: "en-US") != nil, "English system voice")
        check(AVSpeechSynthesisVoice(language: "en-GB") != nil, "British English system voice")
        check(AVSpeechSynthesisVoice(language: "zh-CN") != nil, "Chinese system voice")
        check(EnglishAccent.american.localeIdentifier == "en-US", "American accent locale")
        check(EnglishAccent.british.localeIdentifier == "en-GB", "British accent locale")
        check(EnglishAccent.american.controlLabel == "美音 US", "American accent control label")
        check(EnglishAccent.british.controlLabel == "英音 UK", "British accent control label")

        let panelOrigin = PanelPositioner.origin(
            near: CGPoint(x: 990, y: 10),
            panelSize: CGSize(width: 390, height: 420),
            visibleFrame: CGRect(x: 0, y: 0, width: 1_000, height: 800)
        )
        check(panelOrigin.x >= 12 && panelOrigin.y >= 12, "panel screen bounds")

        if failures.isEmpty {
            print("Self-tests passed")
        } else {
            failures.forEach { print("FAILED: \($0)") }
            exit(1)
        }
    }

    private static func check(_ condition: @autoclosure () -> Bool, _ name: String) {
        if !condition() {
            failures.append(name)
        }
    }
}

import XCTest
@testable import FloatTranslate

final class CoreBehaviorTests: XCTestCase {
    func testEnglishChineseLanguagePolicy() {
        XCTAssertEqual(TranslationLanguage.selectableCases, [.simplifiedChinese, .english])
        XCTAssertEqual(LanguagePolicy.resolveSource(for: "on tour"), .automatic(.english))
        XCTAssertEqual(LanguagePolicy.defaultSource(for: "可以提炼"), .simplifiedChinese)
        XCTAssertEqual(LanguagePolicy.defaultTarget(dominantLanguage: .simplifiedChinese), .english)
    }

    func testDictionaryLookupCandidatePolicy() {
        XCTAssertTrue(LookupPolicy.isLookupCandidate("on tour"))
        XCTAssertTrue(LookupPolicy.isLookupCandidate("machine learning"))
        XCTAssertFalse(LookupPolicy.isLookupCandidate("the quick brown fox"))
        XCTAssertFalse(LookupPolicy.isLookupCandidate("a\nb"))
    }

    func testDefinitionFormattingBasics() {
        XCTAssertEqual(DefinitionFormatter.displayPartOfSpeech("noun"), "名词")
        XCTAssertEqual(DefinitionFormatter.displayPhonetics("BrE ˈsɔːs, AmE sɔrs"), "英音 /ˈsɔːs/ · 美音 /sɔrs/")
        XCTAssertEqual(DefinitionFormatter.circledNumber(1), "①")
        XCTAssertEqual(DefinitionFormatter.circledIndex("②"), 2)
    }

    func testTextAndLayoutHelpers() throws {
        XCTAssertEqual(LookupTextNormalizer.normalized("sourceText"), "source text")
        XCTAssertEqual(try TextValidator.validate("  hello \n"), "hello")
        XCTAssertEqual(TranslationCardLayout.panelSize(forMeasuredContentHeight: 900).height, 560)
    }
}

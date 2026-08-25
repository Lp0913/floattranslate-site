import CoreServices
import Foundation

// macOS Dictionary Services. `DCSCopyTextDefinition` is public; the dictionary
// enumeration calls are SPI, declared here by symbol name. They have been stable
// for years and let us pick a useful bilingual dictionary instead of whatever
// happens to be first in the user's active list (often the Apple glossary).
@_silgen_name("DCSCopyAvailableDictionaries")
private func _DCSCopyAvailableDictionaries() -> Unmanaged<CFSet>?

@_silgen_name("DCSDictionaryGetName")
private func _DCSDictionaryGetName(_ dictionary: AnyObject) -> Unmanaged<CFString>?

@_silgen_name("DCSCopyTextDefinition")
private func _DCSCopyTextDefinition(
    _ dictionary: AnyObject?,
    _ string: CFString,
    _ range: CFRange
) -> Unmanaged<CFString>?

// Lower-level record access: lets us read *every* matching entry (e.g. both
// readings of a polyphone like 结果 jiéguǒ "result" / jiēguǒ "bear fruit"),
// which `DCSCopyTextDefinition` collapses to a single one.
@_silgen_name("DCSCopyRecordsForSearchString")
private func _DCSCopyRecordsForSearchString(
    _ dictionary: AnyObject?,
    _ string: CFString,
    _ unused1: UnsafeRawPointer?,
    _ unused2: UnsafeRawPointer?
) -> Unmanaged<CFArray>?

@_silgen_name("DCSRecordCopyDefinition")
private func _DCSRecordCopyDefinition(_ record: AnyObject) -> Unmanaged<CFString>?

/// Decides whether a piece of text is worth a dictionary lookup (a word or
/// short phrase) rather than a sentence to translate.
enum LookupPolicy {
    static let maximumTermLength = 32
    static let maximumWordCount = 3

    static func isLookupCandidate(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maximumTermLength else { return false }
        guard !trimmed.contains(where: \.isNewline) else { return false }
        return trimmed.split(whereSeparator: \.isWhitespace).count <= maximumWordCount
    }
}

enum DictionaryService {
    private struct Entry {
        let name: String
        let ref: AnyObject
    }

    private static let entries: [Entry] = {
        guard let set = _DCSCopyAvailableDictionaries()?.takeRetainedValue() else { return [] }
        return (set as NSSet).allObjects.map { object in
            let ref = object as AnyObject
            let name = (_DCSDictionaryGetName(ref)?.takeUnretainedValue() as String?) ?? ""
            return Entry(name: name, ref: ref)
        }
    }()

    /// Returns one plain-text definition per dictionary entry for `term` — one
    /// for each reading of a polyphone, so all meanings show. Prefers a
    /// dictionary that pairs the source and target languages (e.g. the Oxford
    /// English-Chinese dictionary for either direction of en<->zh) so the senses
    /// come back in a useful language rather than, say, a Bopomofo monolingual
    /// entry. The raw text still carries pinyin; `DefinitionFormatter` strips it.
    static func definitions(
        for term: String,
        sourceLanguage: TranslationLanguage,
        targetLanguage: TranslationLanguage
    ) -> [String] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let cfTerm = trimmed as CFString
        let range = CFRangeMake(0, CFStringGetLength(cfTerm))
        let sourceKeywords = languageKeywords(for: sourceLanguage)
        let targetKeywords = languageKeywords(for: targetLanguage)

        // Only query dictionaries that actually match the language pair. This
        // keeps a word missing from the bilingual dictionary from falling through
        // to an unrelated one (e.g. a Japanese entry for a Chinese headword).
        let ranked = entries
            .filter {
                score($0.name, sourceKeywords) > 0
                    && score($0.name, targetKeywords) > 0
            }
            .sorted {
                score($0.name, sourceKeywords) + score($0.name, targetKeywords)
                    > score($1.name, sourceKeywords) + score($1.name, targetKeywords)
            }

        for entry in ranked {
            let readings = readings(of: cfTerm, matching: trimmed, in: entry.ref)
            if !readings.isEmpty {
                return readings
            }
            // Fall back to the single-definition API if records are unavailable.
            if let result = _DCSCopyTextDefinition(entry.ref, cfTerm, range) {
                let definition = (result.takeRetainedValue() as String)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !definition.isEmpty {
                    return [definition]
                }
            }
        }
        return []
    }

    private static func readings(
        of term: CFString,
        matching query: String,
        in dictionary: AnyObject
    ) -> [String] {
        guard let array = _DCSCopyRecordsForSearchString(dictionary, term, nil, nil)?.takeRetainedValue()
        else { return [] }

        var results: [String] = []
        for index in 0..<CFArrayGetCount(array) {
            guard let pointer = CFArrayGetValueAtIndex(array, index) else { continue }
            let record = unsafeBitCast(pointer, to: AnyObject.self)
            guard let markup = _DCSRecordCopyDefinition(record)?.takeRetainedValue() as String?,
                  markup.contains("class=\"trans\"") else {
                continue  // skip cross-reference-only readings with no real translation
            }
            let text = strippingMarkup(markup)
            if !text.isEmpty, recordMatchesQuery(text, query: query) {
                results.append(text)
            }
        }
        return results
    }

    /// Dictionary search can return similarly spelled records from the opposite
    /// language (for example English "run" also matching Chinese 闰/润). The
    /// plain record starts with its headword before the first pipe, so require an
    /// exact normalized headword before accepting it.
    static func recordMatchesQuery(_ recordText: String, query: String) -> Bool {
        let headword = recordText
            .split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let normalizedHeadword = headword.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
        return !normalizedQuery.isEmpty && normalizedHeadword == normalizedQuery
    }

    private static let tagRegex = try! NSRegularExpression(pattern: "<[^>]+>")

    private static func strippingMarkup(_ markup: String) -> String {
        var text = markup
        if let bodyRange = text.range(of: "<body>") {
            text = String(text[bodyRange.upperBound...])
        }
        let mutable = NSMutableString(string: text)
        tagRegex.replaceMatches(
            in: mutable,
            range: NSRange(location: 0, length: mutable.length),
            withTemplate: ""
        )
        var result = mutable as String
        for (entity, character) in [("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&#160;", " ")] {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func score(_ name: String, _ keywords: [String]) -> Int {
        // The Apple product glossary returns hits for unrelated words; never use it.
        if name == "Apple Dictionary" { return Int.min }
        let lower = name.lowercased()
        var value = 0
        for keyword in keywords where name.contains(keyword) || lower.contains(keyword.lowercased()) {
            value += 10
        }
        guard value > 0 else { return 0 }
        if lower.contains("oxford") { value += 2 }
        return value
    }

    private static func languageKeywords(for target: TranslationLanguage) -> [String] {
        switch target {
        case .simplifiedChinese: ["英汉", "汉英", "汉", "漢", "Chinese"]
        case .english: ["Oxford Dictionary of English", "American", "English", "英"]
        case .japanese: ["英和", "和英", "日", "Japanese"]
        case .korean: ["Korean", "韩", "韓", "한"]
        case .french: ["French", "français", "法"]
        case .german: ["German", "Deutsch", "德"]
        case .spanish: ["Spanish", "Español", "西"]
        }
    }
}

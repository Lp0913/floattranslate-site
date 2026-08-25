import Foundation

/// A dictionary definition parsed into part-of-speech groups and numbered senses
/// so the card can lay it out cleanly instead of showing one run-on blob.
struct FormattedDefinition: Equatable {
    struct Sense: Equatable {
        let gloss: String
        let examples: [String]
        let usageLabels: [String]

        init(gloss: String, examples: [String], usageLabels: [String] = []) {
            self.gloss = gloss
            self.examples = examples
            self.usageLabels = usageLabels
        }
    }

    struct Group: Equatable {
        let partOfSpeech: String
        let senses: [Sense]
    }

    let phonetics: String?
    let groups: [Group]

    var displayPhonetics: String? {
        phonetics.flatMap(DefinitionFormatter.displayPhonetics)
    }

    var isEmpty: Bool {
        groups.allSatisfy { $0.senses.isEmpty }
    }
}

enum DefinitionFormatter {
    private static let toneMarks = "āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜüĀÁǍÀĒÉĚÈĪÍǏÌŌÓǑÒŪÚǓÙ"

    private static let partsOfSpeech = [
        "transitive verb", "intransitive verb", "reflexive verb", "auxiliary verb",
        "modal verb", "plural noun", "singular noun", "adjective", "adverb", "noun", "verb", "pronoun",
        "preposition", "conjunction", "exclamation", "determiner", "abbreviation"
    ]

    private static let chinesePartOfSpeech: [String: String] = [
        "transitive verb": "及物动词",
        "intransitive verb": "不及物动词",
        "reflexive verb": "反身动词",
        "auxiliary verb": "助动词",
        "modal verb": "情态动词",
        "plural noun": "复数名词",
        "singular noun": "单数名词",
        "adjective": "形容词",
        "adverb": "副词",
        "noun": "名词",
        "verb": "动词",
        "pronoun": "代词",
        "preposition": "介词",
        "conjunction": "连词",
        "exclamation": "感叹词",
        "determiner": "限定词",
        "abbreviation": "缩写",
    ]

    private static let chineseSystemLabels: [String: String] = [
        "uncountable": "不可直接计数",
        "countable": "可直接计数",
        "transitive": "及物用法",
        "intransitive": "不及物用法",
        "figurative": "比喻用法",
        "informal": "非正式用法",
        "formal": "正式用法",
        "humorous": "幽默用法",
        "derogatory": "贬义用法",
        "literal": "字面用法",
        "british": "英式用法",
        "mainly british": "主要用于英式英语",
        "us": "美式用法",
        "dated": "旧式用法",
        "literary": "文学用法",
        "technology": "技术领域",
        "computing": "计算机领域",
        "business": "商业领域",
        "law": "法律领域",
        "medicine": "医学领域",
        "music": "音乐领域",
        "sport": "体育领域",
        "transport": "交通运输领域",
        "administration": "行政管理领域",
        "linguistics": "语言学领域",
        "finance": "金融领域",
        "theatre": "戏剧领域",
        "cinema": "电影领域",
        "physics": "物理领域",
        "military": "军事领域",
        "religion": "宗教领域",
        "electricity": "电学领域",
        "astronomy": "天文学领域",
        "politics": "政治领域",
        "predicative": "作表语",
        "usually predicative": "通常作表语",
        "attributive": "作定语",
        "usually attributive": "通常作定语",
        "plus singular verb": "也可接单数动词",
    ]

    private static let pinyinRegex = try! NSRegularExpression(
        pattern: "[A-Za-züɡ]*[\(toneMarks)][A-Za-züɡ]*(?:\\s+(?:de|le|zi|guo|ge|men|er))*"
    )

    private static let bopomofoRegex = try! NSRegularExpression(
        pattern: "[\\x{3105}-\\x{312F}\\x{31A0}-\\x{31BF}\\x{02C7}\\x{02C9}\\x{02CA}\\x{02CB}\\x{02D9}]+"
    )

    private static let leadingSystemLabelRegex = try! NSRegularExpression(
        pattern: "^(?:and\\s+)?(usually\\s+predicative|usually\\s+attributive|mainly\\s+british|plus\\s+singular\\s+verb|uncountable|countable|transitive|intransitive|predicative|attributive|figurative|informal|formal|humorous|derogatory|literal|british|us|dated|literary|technology|computing|business|law|medicine|music|sport|transport|administration|linguistics|finance|theatre|cinema|physics|military|religion|electricity|astronomy|politics)\\b[.,:]?\\s*",
        options: [.caseInsensitive]
    )

    private static let inlineSystemLabelRegex = try! NSRegularExpression(
        pattern: "\\b(figurative|literal|informal|formal|humorous|derogatory|Law|Finance|Technology|Computing|Business|Medicine|Music|Sport|Transport|Administration|Linguistics|Theatre|Cinema|Physics|Military|Religion|Electricity|Astronomy|Politics|US)\\b[.,:]?",
        options: [.caseInsensitive]
    )

    private static let dictionaryAbbreviationRegex = try! NSRegularExpression(
        pattern: "\\b(sb|sth)(?:'s)?\\b|\\bfig\\.",
        options: [.caseInsensitive]
    )

    private static let inlinePartOfSpeechRegex = try! NSRegularExpression(
        pattern: "^(.+?)\\s+(\(partsOfSpeech.joined(separator: "|")))\\s+(.+)$",
        options: [.caseInsensitive]
    )

    static func removePinyin(_ text: String) -> String {
        let mutable = NSMutableString(string: text)
        bopomofoRegex.replaceMatches(in: mutable, range: NSRange(location: 0, length: mutable.length), withTemplate: "")
        pinyinRegex.replaceMatches(in: mutable, range: NSRange(location: 0, length: mutable.length), withTemplate: "")
        var result = mutable as String
        for _ in 0..<3 {
            result = result
                .replacingOccurrences(of: "  ", with: " ")
                .replacingOccurrences(of: " ;", with: "; ")
                .replacingOccurrences(of: " ,", with: ", ")
                .replacingOccurrences(of: " )", with: ")")
                .replacingOccurrences(of: " ›", with: "›")
                .replacingOccurrences(of: "‹ ", with: "‹")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func format(entries: [String]) -> FormattedDefinition {
        var groups: [FormattedDefinition.Group] = []
        var phonetics: String?
        for entry in entries {
            let formatted = format(entry)
            if phonetics == nil { phonetics = formatted.phonetics }
            groups += formatted.groups.filter { !$0.senses.isEmpty }
        }
        return FormattedDefinition(phonetics: phonetics, groups: groups)
    }

    static func format(_ raw: String) -> FormattedDefinition {
        var text = removePinyin(raw)
        for marker in ["PHRASAL VERBS", "PHRASAL VERB"] {
            if let range = text.range(of: marker) {
                text = String(text[..<range.lowerBound])
            }
        }

        var phonetics: String?
        var body = text
        let segments = text
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if segments.count >= 3 {
            let candidate = segments[1]
            phonetics = candidate.isEmpty ? nil : candidate
            body = segments[2...].joined(separator: " | ")
        }

        return FormattedDefinition(phonetics: phonetics, groups: parseGroups(from: body))
    }

    private static func parseGroups(from body: String) -> [FormattedDefinition.Group] {
        let pattern = "([A-Z])\\.\\s+(?:[A-Za-z]+\\s+){0,3}?(\(partsOfSpeech.joined(separator: "|")))"
        let markerRegex = try! NSRegularExpression(pattern: pattern)
        let nsBody = body as NSString
        let matches = markerRegex.matches(in: body, range: NSRange(location: 0, length: nsBody.length))

        guard !matches.isEmpty else {
            var chunk = body.trimmingCharacters(in: .whitespacesAndNewlines)
            var part = partsOfSpeech.first { chunk.lowercased().hasPrefix("\($0) ") } ?? ""
            if !part.isEmpty {
                chunk = String(chunk.dropFirst(part.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            var group = parseGroup(partOfSpeech: part, chunk: chunk)
            if group.partOfSpeech.isEmpty, group.senses.count == 1 {
                let extracted = extractInlinePartOfSpeech(from: group.senses[0].gloss)
                if let detected = extracted.partOfSpeech {
                    group = .init(partOfSpeech: detected, senses: [.init(gloss: extracted.gloss, examples: group.senses[0].examples, usageLabels: group.senses[0].usageLabels)])
                }
            }
            return group.senses.isEmpty ? [] : [group]
        }

        return matches.enumerated().map { index, match in
            let partOfSpeech = nsBody.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            let chunkStart = match.range.location + match.range.length
            let chunkEnd = index + 1 < matches.count ? matches[index + 1].range.location : nsBody.length
            let chunk = nsBody.substring(with: NSRange(location: chunkStart, length: chunkEnd - chunkStart))
            return parseGroup(partOfSpeech: partOfSpeech, chunk: chunk)
        }.filter { !$0.senses.isEmpty }
    }

    private static func parseGroup(partOfSpeech: String, chunk: String) -> FormattedDefinition.Group {
        var senses: [FormattedDefinition.Sense] = []
        var buffer = ""

        func flush() {
            let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            buffer = ""
            guard !trimmed.isEmpty else { return }
            let parts = trimmed.components(separatedBy: "▸")
            let rawGloss = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let (unlocalizedGloss, usageLabels) = extractLeadingSystemLabels(from: rawGloss)
            var gloss = localizeDictionaryMarkers(in: unlocalizedGloss)
            if let extracted = partOfSpeech.isEmpty ? extractInlinePartOfSpeech(from: gloss).gloss : nil {
                gloss = extracted
            }
            guard !gloss.isEmpty else { return }
            let examples = parts.dropFirst()
                .map { localizeDictionaryMarkers(in: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .filter { !$0.isEmpty }
            senses.append(.init(gloss: gloss, examples: Array(examples.prefix(3)), usageLabels: usageLabels))
        }

        for character in chunk {
            if circledIndex(character) != nil {
                flush()
            } else {
                buffer.append(character)
            }
        }
        flush()

        var resolvedPart = partOfSpeech
        if resolvedPart.isEmpty {
            let detected = senses.compactMap { extractInlinePartOfSpeech(from: $0.gloss).partOfSpeech }
            if Set(detected).count == 1 { resolvedPart = detected.first ?? "" }
        }
        return .init(partOfSpeech: resolvedPart, senses: senses)
    }

    private static func extractInlinePartOfSpeech(from raw: String) -> (gloss: String, partOfSpeech: String?) {
        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        guard let match = inlinePartOfSpeechRegex.firstMatch(in: raw, range: range),
              let prefixRange = Range(match.range(at: 1), in: raw),
              let partRange = Range(match.range(at: 2), in: raw),
              let suffixRange = Range(match.range(at: 3), in: raw) else {
            return (raw, nil)
        }
        let prefix = String(raw[prefixRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard prefix.unicodeScalars.contains(where: { (0x3400...0x9FFF).contains($0.value) }) else {
            return (raw, nil)
        }
        let part = String(raw[partRange]).lowercased()
        let suffix = String(raw[suffixRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        return ("\(prefix) \(suffix)", part)
    }

    static func circledIndex(_ character: Character) -> Int? {
        guard character.unicodeScalars.count == 1, let scalar = character.unicodeScalars.first else { return nil }
        if scalar.value >= 0x2460, scalar.value <= 0x2473 { return Int(scalar.value - 0x2460) + 1 }
        if scalar.value >= 0x3251, scalar.value <= 0x325F { return Int(scalar.value - 0x3251) + 21 }
        return nil
    }

    static func circledNumber(_ index: Int) -> String {
        if index >= 21, index <= 35, let scalar = Unicode.Scalar(0x3251 + index - 21) {
            return String(scalar)
        }
        guard index >= 1, index <= 20, let scalar = Unicode.Scalar(0x2460 + index - 1) else {
            return "\(index)."
        }
        return String(scalar)
    }

    static func displayPartOfSpeech(_ raw: String) -> String? {
        chinesePartOfSpeech[raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)]
    }

    static func usageLabelHelp(_ label: String) -> String {
        switch label {
        case "不可直接计数": "这个含义通常不能用一个、两个直接计数"
        case "可直接计数": "这个含义可以用一个、两个等数量来计数"
        case "及物用法": "这个动词用法后面可以直接接宾语"
        case "不及物用法": "这个动词用法后面不能直接接宾语"
        case "比喻用法": "这个含义用于比喻，不是字面含义"
        case "非正式用法": "常用于口语或非正式场合"
        case "正式用法": "常用于正式表达或书面语"
        case "幽默用法": "这个含义通常带有幽默色彩"
        case "贬义用法": "这个含义通常带有贬义"
        default: label
        }
    }

    private static func extractLeadingSystemLabels(from raw: String) -> (String, [String]) {
        var gloss = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var labels: [String] = []
        while true {
            let range = NSRange(gloss.startIndex..<gloss.endIndex, in: gloss)
            guard let match = leadingSystemLabelRegex.firstMatch(in: gloss, range: range),
                  let labelRange = Range(match.range(at: 1), in: gloss),
                  let wholeRange = Range(match.range(at: 0), in: gloss) else { break }
            let rawLabel = String(gloss[labelRange]).lowercased()
            if let localized = chineseSystemLabels[rawLabel], !labels.contains(localized) {
                labels.append(localized)
            }
            gloss.removeSubrange(wholeRange)
            gloss = gloss.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return (gloss, labels)
    }

    static func localizeDictionaryMarkers(in raw: String) -> String {
        localizeInlineSystemLabels(in: localizeDictionaryAbbreviations(in: raw))
            .replacingOccurrences(of: " ()", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func localizeInlineSystemLabels(in raw: String) -> String {
        let matches = inlineSystemLabelRegex.matches(in: raw, range: NSRange(raw.startIndex..<raw.endIndex, in: raw))
        var result = raw
        for match in matches.reversed() {
            guard let markerRange = Range(match.range(at: 1), in: raw),
                  let wholeRange = Range(match.range(at: 0), in: result) else { continue }
            let marker = String(raw[markerRange]).lowercased()
            guard let localized = chineseSystemLabels[marker] else { continue }
            result.replaceSubrange(wholeRange, with: "【\(localized)】")
        }
        return result
    }

    static func localizeDictionaryAbbreviations(in raw: String) -> String {
        let matches = dictionaryAbbreviationRegex.matches(in: raw, range: NSRange(raw.startIndex..<raw.endIndex, in: raw))
        var result = raw
        for match in matches.reversed() {
            guard let wholeRangeInRaw = Range(match.range(at: 0), in: raw),
                  let wholeRange = Range(match.range(at: 0), in: result) else { continue }
            let marker = String(raw[wholeRangeInRaw]).lowercased()
            let replacement: String
            switch marker {
            case "sb": replacement = "某人"
            case "sb's": replacement = "某人的"
            case "sth": replacement = "某物"
            case "sth's": replacement = "某物的"
            case "fig.": replacement = "比喻"
            default: continue
            }
            result.replaceSubrange(wholeRange, with: replacement)
        }
        return result
    }

    static func displayPhonetics(_ raw: String) -> String? {
        let parts = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(formatPhoneticPart)
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func formatPhoneticPart(_ part: String) -> String? {
        let mappings = [("BrE", "英音"), ("British", "英音"), ("AmE", "美音"), ("American", "美音"), ("NAmE", "美音")]
        for (prefix, label) in mappings where part.hasPrefix(prefix) {
            let value = part.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return nil }
            return "\(label) \(wrapWithSlashes(value))"
        }
        return wrapWithSlashes(part)
    }

    private static func wrapWithSlashes(_ value: String) -> String {
        if value.hasPrefix("/") || value.hasPrefix("[") { return value }
        return "/\(value)/"
    }
}

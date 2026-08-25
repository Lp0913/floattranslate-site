import Foundation

enum LookupTextNormalizer {
    static func normalized(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        guard isCodeIdentifier(trimmed) else { return trimmed }

        var result = ""
        var previous: Character?
        for character in trimmed {
            if shouldInsertSpace(before: character, after: previous) {
                result.append(" ")
            }
            if character == "_" || character == "-" {
                result.append(" ")
            } else {
                result.append(character)
            }
            previous = character
        }

        return result
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .lowercased()
    }

    private static func isCodeIdentifier(_ text: String) -> Bool {
        guard !text.contains(where: \.isWhitespace) else { return false }
        let scalars = text.unicodeScalars
        guard scalars.allSatisfy({
            CharacterSet.alphanumerics.contains($0) || $0 == "_" || $0 == "-"
        }) else { return false }

        if text.contains("_") || text.contains("-") {
            return true
        }

        var previous: Character?
        for character in text {
            if let previous, previous.isLowercase && character.isUppercase {
                return true
            }
            previous = character
        }
        return false
    }

    private static func shouldInsertSpace(before character: Character, after previous: Character?) -> Bool {
        guard let previous else { return false }
        return previous.isLowercase && character.isUppercase
    }
}

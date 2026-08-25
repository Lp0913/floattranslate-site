import Foundation

enum TextValidationError: LocalizedError, Equatable {
    case emptySelection
    case tooLong(limit: Int)

    var errorDescription: String? {
        switch self {
        case .emptySelection:
            "没有读取到选中的文本"
        case let .tooLong(limit):
            "选中的文本超过 \(limit) 个字符"
        }
    }
}

enum TextValidator {
    static let maximumCharacterCount = 5_000

    static func validate(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TextValidationError.emptySelection
        }
        guard trimmed.count <= maximumCharacterCount else {
            throw TextValidationError.tooLong(limit: maximumCharacterCount)
        }
        return trimmed
    }
}

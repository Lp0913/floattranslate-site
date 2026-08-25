import Foundation

enum TranslationErrorMessage {
    static func message(for error: Error) -> String {
        if error is CancellationError {
            return "翻译已取消，请重试"
        }

        let description = error.localizedDescription
        let lowercaseDescription = description.lowercased()
        if lowercaseDescription.contains("cancelled")
            || lowercaseDescription.contains("canceled")
            || description.contains("取消") {
            return "翻译已取消，请重试"
        }

        return description
    }
}

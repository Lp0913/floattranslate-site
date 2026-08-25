import Foundation

enum EnglishAccent: String, CaseIterable, Identifiable {
    case american
    case british

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .american: "美音"
        case .british: "英音"
        }
    }

    var controlLabel: String {
        switch self {
        case .american: "美音 US"
        case .british: "英音 UK"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .american: "en-US"
        case .british: "en-GB"
        }
    }
}

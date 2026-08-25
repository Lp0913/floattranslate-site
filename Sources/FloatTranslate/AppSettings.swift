import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let hotKeyChoice = "hotKeyChoice"
        static let englishAccent = "englishAccent"
    }

    @Published var hotKeyChoice: HotKeyChoice {
        didSet {
            UserDefaults.standard.set(hotKeyChoice.rawValue, forKey: Keys.hotKeyChoice)
            onHotKeyChoiceChanged?(hotKeyChoice)
        }
    }

    @Published var englishAccent: EnglishAccent {
        didSet {
            UserDefaults.standard.set(englishAccent.rawValue, forKey: Keys.englishAccent)
        }
    }

    var onHotKeyChoiceChanged: ((HotKeyChoice) -> Void)?

    init() {
        hotKeyChoice = UserDefaults.standard.string(forKey: Keys.hotKeyChoice)
            .flatMap(HotKeyChoice.init(rawValue:)) ?? .optionSpace
        englishAccent = UserDefaults.standard.string(forKey: Keys.englishAccent)
            .flatMap(EnglishAccent.init(rawValue:)) ?? .american
    }
}

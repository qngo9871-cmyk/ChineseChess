import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case en
    case zhHant = "zh-Hant"
    var id: String { rawValue }
    var displayName: String { self == .en ? "English" : "繁體中文" }
}

/// Manual bundle-swap localizer so the in-app language can change at runtime
/// without relaunching (system Locale-driven Text() only picks up the language
/// on next app launch, which isn't enough for an in-app switcher). Same pattern
/// as Dara/Surakarta/Klotski's LocalizationManager.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
            bundle = Self.bundle(for: language)
        }
    }

    private var bundle: Bundle = .main

    init() {
        let stored = UserDefaults.standard.string(forKey: "app_language")
        let lang = AppLanguage(rawValue: stored ?? "") ?? Self.systemDefault()
        self.language = lang
        self.bundle = Self.bundle(for: lang)
    }

    private static func systemDefault() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh") ? .zhHant : .en
    }

    private static func bundle(for lang: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: lang.rawValue, ofType: "lproj"),
              let b = Bundle(path: path) else { return .main }
        return b
    }

    func setLanguage(_ lang: AppLanguage) {
        language = lang
    }

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

/// Shorthand: L("home.title") looks up the current in-app language, live.
func L(_ key: String) -> String {
    LocalizationManager.shared.string(key)
}

/// A segmented-look language switcher built entirely in SwiftUI (no
/// Picker(.segmented) / UISegmentedControl bridging) — that bridging is a
/// known source of a highlight-vs-persisted-language desync bug elsewhere in
/// this portfolio (see Dara's LanguageSwitcher for the full writeup).
struct LanguageSwitcher: View {
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    loc.setLanguage(lang)
                } label: {
                    segmentLabel(for: lang)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .animation(.easeInOut(duration: 0.15), value: loc.language)
    }

    @ViewBuilder
    private func segmentLabel(for lang: AppLanguage) -> some View {
        let isSelected = loc.language == lang
        Text(lang.displayName)
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(segmentBackground(isSelected: isSelected))
    }

    @ViewBuilder
    private func segmentBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 1.5, y: 0.5)
        } else {
            Color.clear
        }
    }
}

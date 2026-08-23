import SwiftUI

@main
struct ChineseChessApp: App {
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var localizationManager = LocalizationManager.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(purchaseManager)
                .environmentObject(localizationManager)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if DEBUG
        if ProcessInfo.processInfo.environment["CC_SKIP_ONBOARDING"] != nil {
            HomeView()
        } else if !hasSeenOnboarding {
            OnboardingView(onFinished: { hasSeenOnboarding = true })
        } else {
            HomeView()
        }
        #else
        if !hasSeenOnboarding {
            OnboardingView(onFinished: { hasSeenOnboarding = true })
        } else {
            HomeView()
        }
        #endif
    }
}

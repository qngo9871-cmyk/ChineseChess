import SwiftUI

/// Home screen with game mode selection.
struct HomeView: View {

    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var loc: LocalizationManager
    @State private var selectedDifficulty: AIDifficulty = .beginner
    @State private var navigateToAI = false
    @State private var navigateToLocal = false
    @State private var showUpgrade = false
    @State private var upgradeFeature = ""
    @State private var showHowToPlay = false

    private func isLocked(_ level: AIDifficulty) -> Bool {
        if purchaseManager.isPro { return false }
        if level.requiresPro { return true }
        return !purchaseManager.trialActive
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Title
                Text(L("home.title"))
                    .font(.largeTitle.bold())
                Text("象棋  Xiangqi")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                if !purchaseManager.isPro && purchaseManager.trialActive {
                    Text(String(format: L("home.trial"), purchaseManager.trialDaysRemaining))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // AI game section
                VStack(spacing: 12) {
                    Picker(L("home.difficulty"), selection: $selectedDifficulty) {
                        ForEach(AIDifficulty.allCases) { level in
                            HStack {
                                Text(L(level.titleKey))
                                if isLocked(level) {
                                    Image(systemName: "lock.fill")
                                }
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)
                    .onChange(of: selectedDifficulty) { _, newValue in
                        if isLocked(newValue) {
                            upgradeFeature = String(format: L("upgrade.feature.difficulty"), L(newValue.titleKey))
                            showUpgrade = true
                        }
                    }

                    Button {
                        if isLocked(selectedDifficulty) {
                            upgradeFeature = String(format: L("upgrade.feature.difficulty"), L(selectedDifficulty.titleKey))
                            showUpgrade = true
                        } else {
                            navigateToAI = true
                        }
                    } label: {
                        Label(L("home.playvsai"), systemImage: "cpu")
                            .frame(maxWidth: 220)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                // Local two-player
                Button {
                    if !purchaseManager.isPro {
                        upgradeFeature = L("home.playvsfriend")
                        showUpgrade = true
                    } else {
                        navigateToLocal = true
                    }
                } label: {
                    HStack {
                        Label(L("home.playvsfriend"), systemImage: "person.2")
                            .frame(maxWidth: 190)
                        if !purchaseManager.isPro {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    showHowToPlay = true
                } label: {
                    Text(L("home.howtoplay"))
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Spacer()

                LanguageSwitcher()
                    .frame(maxWidth: 280)

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("v\(version) (\(build))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationDestination(isPresented: $navigateToAI) {
                GameView(aiEngine: AIEngine(difficulty: selectedDifficulty))
            }
            .navigationDestination(isPresented: $navigateToLocal) {
                GameView()
            }
            .sheet(isPresented: $showUpgrade) {
                UpgradeView(feature: upgradeFeature)
                    .environmentObject(purchaseManager)
                    .environmentObject(loc)
            }
            .sheet(isPresented: $showHowToPlay) {
                OnboardingView(onFinished: { showHowToPlay = false })
                    .environmentObject(loc)
            }
            .onAppear {
                #if DEBUG
                // Screenshot/QA capture hooks, inert in production:
                // - CC_SHOW_PAYWALL: force the upgrade sheet open (for paywall screenshots).
                // - CC_CAPTURE != "home": jump into a local (no-AI) game so the seeded
                //   board holds still for gameplay screenshots.
                if ProcessInfo.processInfo.environment["CC_SHOW_PAYWALL"] != nil {
                    upgradeFeature = L("home.playvsfriend")
                    showUpgrade = true
                } else if let name = ProcessInfo.processInfo.environment["CC_CAPTURE"], name != "home" {
                    navigateToLocal = true
                }
                #endif
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(PurchaseManager())
        .environmentObject(LocalizationManager.shared)
}

import SwiftUI

/// Home screen with game mode selection.
struct HomeView: View {

    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var selectedDifficulty: AIDifficulty = .beginner
    @State private var navigateToAI = false
    @State private var navigateToLocal = false
    @State private var showUpgrade = false
    @State private var upgradeFeature = ""

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
                Text("Chinese Chess")
                    .font(.largeTitle.bold())
                Text("象棋  Xiangqi")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                if !purchaseManager.isPro && purchaseManager.trialActive {
                    Text("Free trial — \(purchaseManager.trialDaysRemaining) day\(purchaseManager.trialDaysRemaining == 1 ? "" : "s") left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // AI game section
                VStack(spacing: 12) {
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(AIDifficulty.allCases) { level in
                            HStack {
                                Text(level.rawValue)
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
                            upgradeFeature = "\(newValue.rawValue) difficulty"
                            showUpgrade = true
                        }
                    }

                    Button {
                        if isLocked(selectedDifficulty) {
                            upgradeFeature = "\(selectedDifficulty.rawValue) difficulty"
                            showUpgrade = true
                        } else {
                            navigateToAI = true
                        }
                    } label: {
                        Label("Play vs AI", systemImage: "cpu")
                            .frame(maxWidth: 220)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                // Local two-player
                Button {
                    if !purchaseManager.isPro {
                        upgradeFeature = "Play vs Friend"
                        showUpgrade = true
                    } else {
                        navigateToLocal = true
                    }
                } label: {
                    HStack {
                        Label("Play vs Friend", systemImage: "person.2")
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

                Spacer()

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
            }
            .onAppear {
                #if DEBUG
                // Screenshot capture: any CC_CAPTURE other than "home" jumps into a
                // local (no-AI) game so the seeded board holds still. Inert in production.
                if let name = ProcessInfo.processInfo.environment["CC_CAPTURE"], name != "home" {
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
}

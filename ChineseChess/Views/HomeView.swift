import SwiftUI

/// Home screen with game mode selection.
struct HomeView: View {

    @State private var selectedDifficulty: AIDifficulty = .medium
    @State private var navigateToAI = false
    @State private var navigateToLocal = false

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

                Spacer()

                // AI game section
                VStack(spacing: 12) {
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(AIDifficulty.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)

                    Button {
                        navigateToAI = true
                    } label: {
                        Label("Play vs AI", systemImage: "cpu")
                            .frame(maxWidth: 220)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                // Local two-player
                Button {
                    navigateToLocal = true
                } label: {
                    Label("Play vs Friend", systemImage: "person.2")
                        .frame(maxWidth: 220)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToAI) {
                GameView(aiEngine: AIEngine(difficulty: selectedDifficulty))
            }
            .navigationDestination(isPresented: $navigateToLocal) {
                GameView()
            }
        }
    }
}

#Preview {
    HomeView()
}

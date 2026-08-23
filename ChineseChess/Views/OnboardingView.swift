import SwiftUI

/// Four-page first-launch walkthrough: the river/palace board layout, the
/// General's palace restriction, the seven piece types, and the win
/// condition. Shown once, re-accessible from Home via "How to Play".
struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var page: Int = {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["CC_ONBOARDING_PAGE"], let p = Int(raw) { return p }
        #endif
        return 0
    }()

    private let pageKeys: [(title: String, body: String)] = [
        ("onboarding.page1.title", "onboarding.page1.body"),
        ("onboarding.page2.title", "onboarding.page2.body"),
        ("onboarding.page3.title", "onboarding.page3.body"),
        ("onboarding.page4.title", "onboarding.page4.body"),
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(L(pageKeys[page].title))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(L(pageKeys[page].body))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 8) {
                ForEach(0..<pageKeys.count, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            Button {
                if page < pageKeys.count - 1 {
                    page += 1
                } else {
                    onFinished()
                }
            } label: {
                Text(page < pageKeys.count - 1 ? L("onboarding.next") : L("onboarding.start"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
        .environmentObject(LocalizationManager.shared)
}

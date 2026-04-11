import SwiftUI

@main
struct ChineseChessApp: App {
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(purchaseManager)
        }
    }
}

import SwiftUI

struct UpgradeView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss

    let feature: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(purchaseManager.trialActive ? L("upgrade.title") : L("upgrade.title.trialended"))
                .font(.title2.bold())

            Text(purchaseManager.trialActive
                 ? String(format: L("upgrade.subtitle"), feature)
                 : String(format: L("upgrade.subtitle.trialended"), feature))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 8) {
                Text(L("upgrade.whatyouget"))
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text(L("upgrade.feature1"))
                        .font(.subheadline)
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text(L("upgrade.feature2"))
                        .font(.subheadline)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.15))
            )
            .padding(.horizontal, 32)

            Spacer()

            // Purchase section
            VStack(spacing: 12) {
                if let product = purchaseManager.product {
                    Button {
                        Task { await purchaseManager.purchase() }
                    } label: {
                        if purchaseManager.isPurchasing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(String(format: L("upgrade.unlock"), product.displayPrice))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(purchaseManager.isPurchasing)
                } else if purchaseManager.productLoadFailed {
                    VStack(spacing: 8) {
                        Text(L("upgrade.loadfailed"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(L("upgrade.checkconnection"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(L("upgrade.tryagain")) {
                            Task { await purchaseManager.loadProduct() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ProgressView(L("upgrade.loading"))
                }

                Button {
                    Task { await purchaseManager.restorePurchases() }
                } label: {
                    Text(L("upgrade.restore"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .disabled(purchaseManager.isPurchasing)

                if let error = purchaseManager.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .task {
            if purchaseManager.product == nil && !purchaseManager.isLoadingProduct {
                await purchaseManager.loadProduct()
            }
        }
        .onChange(of: purchaseManager.isPro) {
            if purchaseManager.isPro {
                dismiss()
            }
        }
    }
}

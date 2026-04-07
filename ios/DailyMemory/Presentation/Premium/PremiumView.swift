import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreKitService.shared
    @State private var selectedPlan: String = StoreKitService.yearlyID

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.dmPrimary, .dmPrimaryLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 72, height: 72)

                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }

                        Text("Upgrade to Premium")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Unlock the full power of your AI memory companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "brain.head.profile", title: "200 AI analyses / day", subtitle: "vs 30 on free tier")
                        FeatureRow(icon: "photo.stack", title: "100 image analyses / day", subtitle: "vs 10 on free tier")
                        FeatureRow(icon: "magnifyingglass", title: "500 semantic searches / day", subtitle: "vs 50 on free tier")
                        FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Priority cloud sync", subtitle: "Faster, more reliable")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced insights", subtitle: "Weekly & monthly AI reports")
                        FeatureRow(icon: "heart.fill", title: "Support development", subtitle: "Help us build more features")
                    }
                    .padding(.horizontal, 24)

                    // Plan Selection
                    VStack(spacing: 12) {
                        if let yearly = store.yearlyProduct {
                            PlanCard(
                                product: yearly,
                                label: "Yearly",
                                badge: "Best Value",
                                isSelected: selectedPlan == StoreKitService.yearlyID,
                                onTap: { selectedPlan = StoreKitService.yearlyID }
                            )
                        }

                        if let monthly = store.monthlyProduct {
                            PlanCard(
                                product: monthly,
                                label: "Monthly",
                                badge: nil,
                                isSelected: selectedPlan == StoreKitService.monthlyID,
                                onTap: { selectedPlan = StoreKitService.monthlyID }
                            )
                        }

                        if store.products.isEmpty && !store.isLoading {
                            Text("Products not available yet.\nConfigure in App Store Connect first.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 24)

                    // Purchase Button
                    Button {
                        Task {
                            guard let product = store.products.first(where: { $0.id == selectedPlan }) else { return }
                            let success = await store.purchase(product)
                            if success { dismiss() }
                        }
                    } label: {
                        HStack {
                            if store.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Subscribe Now")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                colors: [.dmPrimary, .dmPrimaryDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                    .disabled(store.isLoading || store.products.isEmpty)
                    .padding(.horizontal, 24)

                    // Restore + Terms
                    VStack(spacing: 8) {
                        Button("Restore Purchases") {
                            Task { await store.restorePurchases() }
                        }
                        .font(.footnote)
                        .foregroundColor(.accentColor)

                        Text("Subscription auto-renews. Cancel anytime in Settings.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Error", isPresented: .constant(store.error != nil)) {
                Button("OK") { }
            } message: {
                Text(store.error ?? "")
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.dmPrimary)
                .frame(width: 36, height: 36)
                .background(Color.dmPrimary.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let label: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.headline)
                            .fontWeight(.semibold)

                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.dmAccent)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                        }
                    }

                    Text(product.displayPrice + " / " + (label == "Yearly" ? "year" : "month"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .dmPrimary : .secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.dmPrimary : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PremiumView()
}

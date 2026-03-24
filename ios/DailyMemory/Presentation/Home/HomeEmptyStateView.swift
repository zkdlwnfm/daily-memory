import SwiftUI

struct HomeEmptyStateView: View {
    let onStartRecording: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Welcome Header
                welcomeHeader
                    .padding(.top, 24)

                // Main CTA Card
                ctaCard
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                // Example Section
                exampleSection
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        VStack(spacing: 8) {
            Text("Welcome! 👋")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Let's capture your first memory")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - CTA Card
    private var ctaCard: some View {
        VStack(spacing: 24) {
            Text("📝")
                .font(.system(size: 48))

            VStack(spacing: 12) {
                Text("Record your first memory")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text("Speak or type what happened today. AI will organize it for you into your personal timeline.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onStartRecording) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                    Text("🎉 Start Recording")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundColor(.white)
                .background(Color.dmPrimary)
                .cornerRadius(16)
            }
        }
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Example Section
    private var exampleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💡 TRY RECORDING SOMETHING LIKE...")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(1)

            ForEach(exampleMemories, id: \.self) { example in
                ExampleCard(text: example)
            }
        }
    }

    private var exampleMemories: [String] {
        [
            "Had coffee with Sarah today. She mentioned her new job starts Monday.",
            "Mom sent $200 for my birthday. Should call to thank her."
        ]
    }
}

// MARK: - Example Card
struct ExampleCard: View {
    let text: String

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.dmPrimary.opacity(0.3))
                .frame(width: 4)

            Text("\"\(text)\"")
                .font(.body)
                .italic()
                .foregroundColor(.secondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

#Preview {
    HomeEmptyStateView(onStartRecording: {})
}

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            title: "Your AI Memory\nCompanion",
            subtitle: "Record your daily moments with voice or text. AI automatically organizes and analyzes everything for you.",
            color: .blue
        ),
        OnboardingPage(
            icon: "waveform.and.mic",
            title: "Just Speak",
            subtitle: "Talk naturally about your day. Speech recognition captures every word, and AI extracts people, places, and events.",
            color: .purple
        ),
        OnboardingPage(
            icon: "magnifyingglass.circle.fill",
            title: "Search by Meaning",
            subtitle: "Ask questions like \"When did I last meet Sarah?\" and get intelligent answers from your memories.",
            color: .orange
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            title: "Never Forget",
            subtitle: "Smart reminders for promises, events, and important dates. Location-based alerts when you arrive somewhere.",
            color: .green
        )
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation { completeOnboarding() }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }
                .frame(height: 44)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? pages[currentPage].color : Color.secondary.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Button
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            completeOnboarding()
                        }
                    }
                } label: {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                            .fontWeight(.semibold)
                        if currentPage == pages.count - 1 {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(pages[currentPage].color)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private func completeOnboarding() {
        isOnboardingCompleted = true
        UserPreferences.shared.isOnboarded = true
    }
}

// MARK: - Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(page.color.opacity(0.06))
                    .frame(width: 220, height: 220)

                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundColor(page.color)
            }

            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Subtitle
            Text(page.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    OnboardingView(isOnboardingCompleted: .constant(false))
}

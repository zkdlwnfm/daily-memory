import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let bgGradient: [Color]
}

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            title: "Your AI Memory\nCompanion",
            subtitle: "Record your daily moments with voice or text.\nAI automatically organizes everything for you.",
            accentColor: .dmPrimary,
            bgGradient: [Color(hex: "3D5A50").opacity(0.08), Color(hex: "3D5A50").opacity(0.02)]
        ),
        OnboardingPage(
            icon: "waveform.and.mic",
            title: "Just Speak",
            subtitle: "Talk naturally about your day.\nSpeech recognition captures every word.",
            accentColor: Color(hex: "6B5B95"),
            bgGradient: [Color(hex: "6B5B95").opacity(0.08), Color(hex: "6B5B95").opacity(0.02)]
        ),
        OnboardingPage(
            icon: "magnifyingglass.circle.fill",
            title: "Search by Meaning",
            subtitle: "Ask \"When did I last meet Sarah?\"\nand get intelligent answers from your memories.",
            accentColor: Color(hex: "C4784D"),
            bgGradient: [Color(hex: "C4784D").opacity(0.08), Color(hex: "C4784D").opacity(0.02)]
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            title: "Never Forget",
            subtitle: "Smart reminders for promises and events.\nLocation-based alerts when you arrive.",
            accentColor: Color(hex: "22C55E"),
            bgGradient: [Color(hex: "22C55E").opacity(0.08), Color(hex: "22C55E").opacity(0.02)]
        )
    ]

    var body: some View {
        ZStack {
            // Dynamic background
            LinearGradient(
                colors: pages[currentPage].bgGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    // Page counter
                    Text("\(currentPage + 1)/\(pages.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.leading, Spacing.lg)

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation { completeOnboarding() }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.trailing, Spacing.lg)
                    }
                }
                .frame(height: 44)
                .padding(.top, Spacing.sm)

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
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? pages[currentPage].accentColor : Color.secondary.opacity(0.2))
                            .frame(width: index == currentPage ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, Spacing.xl)

                // Button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.4)) {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            completeOnboarding()
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                            .fontWeight(.bold)
                        if currentPage == pages.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(pages[currentPage].accentColor)
                    .cornerRadius(Radius.md)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
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
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Layered illustration circles
            ZStack {
                // Outer ring
                Circle()
                    .stroke(page.accentColor.opacity(0.08), lineWidth: 2)
                    .frame(width: 200, height: 200)

                // Middle fill
                Circle()
                    .fill(page.accentColor.opacity(0.06))
                    .frame(width: 160, height: 160)

                // Inner fill
                Circle()
                    .fill(page.accentColor.opacity(0.1))
                    .frame(width: 110, height: 110)

                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(page.accentColor)
            }

            VStack(spacing: Spacing.sm) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, Spacing.lg)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

#Preview {
    OnboardingView(isOnboardingCompleted: .constant(false))
}

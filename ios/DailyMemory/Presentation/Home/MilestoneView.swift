import SwiftUI

/// 스트릭 마일스톤 뱃지 시스템
struct MilestoneBadgesView: View {
    let currentStreak: Int

    private let milestones: [(days: Int, icon: String, label: String, color: Color)] = [
        (7, "flame.fill", "7 days", Color(hex: "F59E0B")),
        (30, "medal.fill", "30 days", Color(hex: "3B82F6")),
        (100, "star.fill", "100 days", Color(hex: "A78BFA")),
        (365, "crown.fill", "1 year", Color(hex: "F59E0B")),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("MILESTONES")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.secondary)

            HStack(spacing: Spacing.sm) {
                ForEach(milestones, id: \.days) { milestone in
                    let achieved = currentStreak >= milestone.days
                    VStack(spacing: Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(achieved ? milestone.color.opacity(0.15) : Color(.systemGray6))
                                .frame(width: 44, height: 44)

                            Image(systemName: milestone.icon)
                                .font(.system(size: 18))
                                .foregroundColor(achieved ? milestone.color : Color(.systemGray4))
                        }

                        Text(milestone.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(achieved ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(achieved ? 1.0 : 0.5)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(Radius.md)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

/// 마일스톤 달성 축하 오버레이
struct MilestoneAchievedOverlay: View {
    let milestone: Int
    @Binding var isPresented: Bool

    private var milestoneInfo: (icon: String, label: String, color: Color) {
        switch milestone {
        case 7: return ("flame.fill", "7-Day Streak!", Color(hex: "F59E0B"))
        case 30: return ("medal.fill", "30-Day Streak!", Color(hex: "3B82F6"))
        case 100: return ("star.fill", "100-Day Streak!", Color(hex: "A78BFA"))
        case 365: return ("crown.fill", "365-Day Streak!", Color(hex: "F59E0B"))
        default: return ("flame.fill", "\(milestone) Days!", Color.dmPrimary)
        }
    }

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }

                VStack(spacing: Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(milestoneInfo.color.opacity(0.15))
                            .frame(width: 100, height: 100)

                        Circle()
                            .fill(milestoneInfo.color.opacity(0.25))
                            .frame(width: 80, height: 80)

                        Image(systemName: milestoneInfo.icon)
                            .font(.system(size: 36))
                            .foregroundColor(milestoneInfo.color)
                    }
                    .scaleEffect(isPresented ? 1.0 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isPresented)

                    Text(milestoneInfo.label)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Amazing consistency! Keep going!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        isPresented = false
                    } label: {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(milestoneInfo.color)
                            .foregroundColor(.white)
                            .cornerRadius(Radius.md)
                    }
                    .padding(.horizontal, Spacing.xl)
                }
                .padding(Spacing.xl)
                .background(.ultraThinMaterial)
                .cornerRadius(Radius.xl)
                .padding(.horizontal, Spacing.xl)
            }
            .transition(.opacity)
        }
    }
}

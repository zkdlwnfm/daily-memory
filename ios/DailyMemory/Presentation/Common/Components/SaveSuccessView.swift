import SwiftUI

/// Full-screen save success overlay with animation
struct SaveSuccessView: View {
    @Binding var isPresented: Bool
    var message: String = "Memory saved"

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var checkmarkTrimEnd: CGFloat = 0
    @State private var particles: [Particle] = []

    var body: some View {
        if isPresented {
            ZStack {
                // Dim background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: 20) {
                    // Animated checkmark
                    ZStack {
                        // Glow
                        Circle()
                            .fill(Color.dmSuccess.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .scaleEffect(scale * 1.3)

                        Circle()
                            .fill(Color.dmSuccess.opacity(0.08))
                            .frame(width: 160, height: 160)
                            .scaleEffect(scale * 1.5)

                        // Circle background
                        Circle()
                            .fill(Color.dmSuccess)
                            .frame(width: 80, height: 80)
                            .scaleEffect(scale)

                        // Checkmark
                        CheckmarkShape()
                            .trim(from: 0, to: checkmarkTrimEnd)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .frame(width: 32, height: 32)
                    }

                    Text(message)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    // Particles
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }
                }
                .opacity(opacity)
            }
            .onAppear { animate() }
        }
    }

    private func animate() {
        // Generate particles
        particles = (0..<12).map { _ in
            Particle(
                color: [Color.dmSuccess, .dmPrimary, .dmAccent, .dmSecondary].randomElement()!,
                size: CGFloat.random(in: 4...8),
                x: 0, y: 0,
                opacity: 1
            )
        }

        // Scale + fade in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1
            opacity = 1
        }

        // Checkmark draw
        withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
            checkmarkTrimEnd = 1
        }

        // Particles burst
        for i in 0..<particles.count {
            let angle = Double(i) / Double(particles.count) * 2 * .pi
            let distance = CGFloat.random(in: 40...80)
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                particles[i].x = cos(angle) * distance
                particles[i].y = sin(angle) * distance
                particles[i].opacity = 0
            }
        }

        // Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            scale = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - Checkmark Shape

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.25))
        return path
    }
}

// MARK: - Particle

struct Particle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

#Preview {
    SaveSuccessView(isPresented: .constant(true))
}

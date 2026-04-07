import SwiftUI

struct SaveSuccessView: View {
    @Binding var isPresented: Bool
    var message: String = "Saved"

    @State private var checkmarkTrimEnd: CGFloat = 0
    @State private var circleScale: CGFloat = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 16) {
                    ZStack {
                        // Circle
                        Circle()
                            .fill(Color.dmPrimary)
                            .frame(width: 64, height: 64)
                            .scaleEffect(circleScale)

                        // Checkmark
                        CheckmarkShape()
                            .trim(from: 0, to: checkmarkTrimEnd)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                            .frame(width: 26, height: 26)
                    }

                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            .onAppear { animate() }
        }
    }

    private func animate() {
        // Circle pop
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            circleScale = 1
        }

        // Checkmark draw
        withAnimation(.easeOut(duration: 0.25).delay(0.15)) {
            checkmarkTrimEnd = 1
        }

        // Text fade
        withAnimation(.easeIn(duration: 0.2).delay(0.3)) {
            textOpacity = 1
        }

        // Haptic
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.15)) {
                isPresented = false
            }
        }
    }
}

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

#Preview {
    SaveSuccessView(isPresented: .constant(true))
}

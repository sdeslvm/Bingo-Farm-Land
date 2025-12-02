import SwiftUI

// MARK: - Протоколы для улучшения расширяемости

protocol ProgressDisplayable {
    var progressPercentage: Int { get }
}

protocol BackgroundProviding {
    associatedtype BackgroundContent: View
    func makeBackground() -> BackgroundContent
}

// MARK: - Расширенная структура загрузки

struct BingoFarmLoadingOverlay: View, ProgressDisplayable {
    let progress: Double
    @State private var glow: Bool = false
    var progressPercentage: Int { Int(progress * 100) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BingoFarmAuroraBackground()
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    BingoFarmOrbitalLoader(progress: progress)
                        .frame(width: min(geo.size.width, geo.size.height) * 0.38,
                               height: min(geo.size.width, geo.size.height) * 0.38)
                        .shadow(color: Color.white.opacity(glow ? 0.35 : 0.1), radius: glow ? 24 : 8)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glow)
                        .onAppear { glow = true }

                    VStack(spacing: 6) {
                        Text("Loading...")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 1)

                        Text("\(progressPercentage)%")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.25), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1)
                    )
                    .cornerRadius(14)
                }
            }
        }
    }
}

// MARK: - Фоновые представления

struct BingoFarmAuroraBackground: View, BackgroundProviding {
    func makeBackground() -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                func blob(_ r: CGFloat, _ speed: Double, _ phase: Double, colors: [Color]) {
                    let x = center.x + cos(t * speed + phase) * r
                    let y = center.y + sin(t * speed + phase * 0.8) * r
                    let circle = Path(ellipseIn: CGRect(x: x - r * 0.9, y: y - r * 0.9, width: r * 1.8, height: r * 1.8))
                    let grad = Gradient(stops: [
                        .init(color: colors[0], location: 0.0),
                        .init(color: colors[1], location: 0.6),
                        .init(color: colors.last ?? .clear, location: 1.0)
                    ])
                    context.fill(circle, with: .radialGradient(grad, center: .init(x: x, y: y), startRadius: 0, endRadius: r * 1.2))
                }

                blob(min(size.width, size.height) * 0.38, 0.25, 0.0, colors: [Color(hex: "#5EEAD4"), Color(hex: "#22D3EE"), Color.clear])
                blob(min(size.width, size.height) * 0.34, 0.18, 1.8, colors: [Color(hex: "#60A5FA"), Color(hex: "#A78BFA"), Color.clear])
                blob(min(size.width, size.height) * 0.30, 0.22, 3.2, colors: [Color(hex: "#F472B6"), Color(hex: "#FB7185"), Color.clear])

                let vignette = Rectangle().path(in: CGRect(origin: .zero, size: size))
                let vignetteGrad = Gradient(stops: [
                    .init(color: .black.opacity(0.0), location: 0.6),
                    .init(color: .black.opacity(0.35), location: 1.0)
                ])
                context.stroke(vignette, with: .color(.clear))
                context.fill(vignette, with: .radialGradient(vignetteGrad, center: .init(x: center.x, y: center.y), startRadius: 0, endRadius: max(size.width, size.height)))
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#0B1020"), Color(hex: "#0A0F1C"), Color(hex: "#0D1324")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .blendMode(.plusLighter)
    }

    var body: some View {
        makeBackground()
    }
}

// MARK: - Orbital Loader

private struct BingoFarmOrbitalLoader: View {
    let progress: Double
    @State private var t: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let minSide = min(size.width, size.height)
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                func dot(radius r: CGFloat, orbit: CGFloat, speed: Double, phase: Double, color: Color) {
                    let x = center.x + cos(time * speed + phase) * orbit
                    let y = center.y + sin(time * speed + phase) * orbit
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    let path = Path(ellipseIn: rect)
                    context.fill(path, with: .color(color))
                    context.stroke(path, with: .color(color.opacity(0.6)), lineWidth: 1)
                }

                // Orbits
                let orbits: [CGFloat] = [0.22, 0.34, 0.46].map { $0 * minSide }
                let colors: [Color] = [Color(hex: "#22D3EE"), Color(hex: "#6366F1"), Color(hex: "#F472B6")]

                for (i, orbit) in orbits.enumerated() {
                    let alpha = 0.35 + 0.15 * sin(time * (0.5 + Double(i) * 0.2))
                    let ring = Path(ellipseIn: CGRect(x: center.x - orbit, y: center.y - orbit, width: orbit * 2, height: orbit * 2))
                    context.stroke(ring, with: .color(colors[i].opacity(alpha)), lineWidth: 1.5)

                    let count = 6 + i * 2
                    for j in 0..<count {
                        let phase = (Double(j) / Double(count)) * .pi * 2
                        dot(radius: max(2, minSide * 0.012 - CGFloat(i) * 0.002),
                            orbit: orbit,
                            speed: 0.6 + Double(i) * 0.22,
                            phase: phase,
                            color: colors[i])
                    }
                }

                // Center pulse indicating progress
                let pulse = 0.08 + 0.08 * sin(time * 2)
                let base = minSide * (0.10 + 0.15 * progress.clamped)
                let centerRect = CGRect(x: center.x - base - base * pulse * 0.5,
                                        y: center.y - base - base * pulse * 0.5,
                                        width: (base * 2) * (1 + pulse * 0.5),
                                        height: (base * 2) * (1 + pulse * 0.5))
                let centerPath = Path(ellipseIn: centerRect)
                let centerGrad = Gradient(stops: [
                    .init(color: Color.white.opacity(0.85), location: 0.0),
                    .init(color: Color.white.opacity(0.0), location: 1.0)
                ])
                context.fill(centerPath, with: .radialGradient(centerGrad, center: .init(x: center.x, y: center.y), startRadius: 0, endRadius: base * 1.2))
            }
        }
    }
}

// MARK: - Helpers

private extension Double {
    var clamped: Double { max(0.0, min(1.0, self)) }
}

// MARK: - Previews

#if canImport(SwiftUI)
import SwiftUI
#endif

// Use availability to keep using the modern #Preview API on iOS 17+ and provide a fallback for older versions
@available(iOS 17.0, *)
#Preview("Vertical") {
    BingoFarmLoadingOverlay(progress: 0.2)
}

@available(iOS 17.0, *)
#Preview("Horizontal", traits: .landscapeRight) {
    BingoFarmLoadingOverlay(progress: 0.2)
}

// Fallback previews for iOS < 17
struct BingoFarmLoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BingoFarmLoadingOverlay(progress: 0.2)
                .previewDisplayName("Vertical (Legacy)")

            BingoFarmLoadingOverlay(progress: 0.2)
                .previewDisplayName("Horizontal (Legacy)")
                .previewLayout(.fixed(width: 812, height: 375)) // Simulate landscape on older previews
        }
    }
}

import SwiftUI

struct LiquidglassModifier: ViewModifier {
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(white: 0.2, opacity: 0.3),
                                    Color(white: 0.1, opacity: 0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Glass reflection
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.25), location: 0),
                                    .init(color: Color.white.opacity(0.15), location: 0.3),
                                    .init(color: Color.clear, location: 0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 1)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.5), radius: 15, x: 8, y: 8)
            .shadow(color: Color(white: 0.3, opacity: 0.5), radius: 15, x: -8, y: -8)
    }
}

extension View {
    func liquidglassStyle(intensity: Double = 1.0) -> some View {
        self.modifier(LiquidglassModifier(intensity: intensity))
    }
}

struct LiquidglassButtonStyle: ButtonStyle {
    var isPlaying: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    // Base layer with top-to-bottom gradient
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: (isPlaying ? 
                                    AppTheme.Colors.Button.normalHighlightBackgroundGradient :
                                    AppTheme.Colors.Button.normalBackgroundGradient).map { color in
                                    color.opacity(configuration.isPressed ? 0.5 : 0.7)
                                }),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.3),
                    radius: configuration.isPressed ? 2 : 4,
                    x: 0,
                    y: configuration.isPressed ? 1 : 3)
            .shadow(color: Color.white.opacity(0.1),
                    radius: configuration.isPressed ? 1 : 2,
                    x: 0,
                    y: configuration.isPressed ? -1 : -2)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct LiquidglassSliderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .tint(AppTheme.Colors.Slider.tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    // Inner shadow effect
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.25),
                                    Color.black.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                .blur(radius: 2)
                                .offset(x: 2, y: 2)
                                .mask(RoundedRectangle(cornerRadius: 12))
                        )

                    // Glass overlay
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.1), location: 0),
                                    .init(color: Color.clear, location: 0.5)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func liquidglassSliderStyle() -> some View {
        self.modifier(LiquidglassSliderStyle())
    }
}

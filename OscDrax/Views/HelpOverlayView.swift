import SwiftUI

struct HelpOverlayView: View {
    let helpItem: HelpDescriptions.HelpItem
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 20) {
                Text(helpItem.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(helpItem.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 20)

                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }, label: {
                    Text("OK")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 44)
                })
                .buttonStyle(LiquidglassButtonStyle())
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.12, green: 0.12, blue: 0.16),
                                Color(red: 0.08, green: 0.08, blue: 0.12)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .frame(maxWidth: 360)
            .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        }
    }
}

struct HelpButton: View {
    let text: String
    let helpItem: HelpDescriptions.HelpItem
    @Binding var currentHelpItem: HelpDescriptions.HelpItem?
    @Binding var showHelp: Bool
    var alignment: Alignment = .leading

    var body: some View {
        Button(action: {
            currentHelpItem = helpItem
            withAnimation(.easeIn(duration: 0.2)) {
                showHelp = true
            }
        }, label: {
            HStack(spacing: 4) {
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 75, alignment: .trailing)

                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
        })
        .frame(width: 95, alignment: alignment)
    }
}

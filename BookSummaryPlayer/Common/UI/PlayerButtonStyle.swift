import SwiftUI

struct PlayerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PlayerButton(configuration: configuration)
    }
    
    struct PlayerButton: View {
        let configuration: ButtonStyle.Configuration
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
        @Environment(\.isEnabled) private var isEnabled: Bool
        
        var body: some View {
            configuration.label
                .padding()
                .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
                .opacity(configuration.isPressed ? 0.6 : 1.0)
                .opacity(isEnabled ? 1 : 0.3)
                .animation(.easeInOut, value: configuration.isPressed)
                .background {
                    Circle()
                        .foregroundStyle(.pressed)
                        .scaleEffect(configuration.isPressed ? 0.9 : 1, anchor: .center)
                        .opacity(configuration.isPressed ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
                }
                .onChange(of: configuration.isPressed) { _, newValue in
                    if newValue {
                        feedbackGenerator.impactOccurred()
                    }
                }
        }
    }
}

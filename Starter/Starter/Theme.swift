import SwiftUI

struct BlackPurpleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func applyThemeBackground() -> some View {
        self.modifier(BlackPurpleBackground())
    }
}

struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // Detect swipe down gesture
                        if value.translation.height > 50 && abs(value.translation.width) < 100 {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
            )
    }
}

extension View {
    func dismissKeyboardOnSwipeDown() -> some View {
        modifier(KeyboardDismissModifier())
    }
}

struct ScrollingText: View {
    let text: String
    let font: Font
    let color: Color
    let speed: Double
    
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isScrolling = false
    
    init(_ text: String, font: Font = .body, color: Color = .primary, speed: Double = 30) {
        self.text = text
        self.font = font
        self.color = color
        self.speed = speed
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeometry.size.width
                                    containerWidth = geometry.size.width
                                    checkIfScrollingNeeded()
                                }
                                .onChange(of: geometry.size.width) { newWidth in
                                    containerWidth = newWidth
                                    checkIfScrollingNeeded()
                                }
                        }
                    )
                
                if isScrolling {
                    Text(text)
                        .font(font)
                        .foregroundColor(color)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.leading, 20) // Gap between repeated text
                }
            }
            .offset(x: offset)
            .animation(.linear(duration: isScrolling ? (textWidth + 20) / speed : 0).repeatForever(autoreverses: false), value: offset)
        }
        .clipped()
    }
    
    private func checkIfScrollingNeeded() {
        if textWidth > containerWidth {
            isScrolling = true
            startScrolling()
        } else {
            isScrolling = false
            offset = 0
        }
    }
    
    private func startScrolling() {
        offset = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            offset = -(textWidth + 20)
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.2))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

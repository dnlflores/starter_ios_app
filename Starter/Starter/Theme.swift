import SwiftUI

struct BlackPurpleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color.purple.opacity(0.6)]),
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

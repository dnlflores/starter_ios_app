import SwiftUI

struct ChatView: View {
    /// Controls presentation of the login sheet from the parent view.
    @Binding var showLogin: Bool
    @AppStorage("authToken") private var authToken: String = ""

    var body: some View {
        ZStack {
            if authToken.isEmpty {
                VStack(spacing: 16) {
                    Text("You are not logged in.")
                        .font(.title2)
                    Button("Log In") {
                        showLogin = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                .padding()
            } else {
                Text("Chat")
                    .font(.largeTitle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
    }
}

#Preview {
    ChatView(showLogin: .constant(false))
}

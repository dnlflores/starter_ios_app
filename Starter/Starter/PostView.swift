import SwiftUI

struct PostView: View {
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
                    .tint(.orange)
                }
                .padding()
            } else {
                Text("Post")
                    .font(.largeTitle)
            }
        }
        .applyThemeBackground()
    }
}

#Preview {
    PostView(showLogin: .constant(false))
}

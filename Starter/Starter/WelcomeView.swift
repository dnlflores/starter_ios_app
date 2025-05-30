import SwiftUI

struct WelcomeView: View {
    let username: String

    var body: some View {
        VStack {
            Spacer()
            Text("Welcome, \(username)!")
                .font(.largeTitle)
                .bold()
                .padding()
            Spacer()
        }
    }
}

#Preview {
    WelcomeView(username: "User")
}

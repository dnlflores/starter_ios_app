import SwiftUI

/// The entry view for the application. The main interface is always
/// accessible. When the user is logged out a "Log In" button can present
/// the login sheet.
struct ContentView: View {
    @AppStorage("username") private var storedUsername: String = "Guest"
    @State private var showLogin = false

    var body: some View {
        MainTabView(username: storedUsername, showLogin: $showLogin)
            .sheet(isPresented: $showLogin) {
                LoginView(showLogin: $showLogin)
            }
    }
}

#Preview {
    ContentView()
}

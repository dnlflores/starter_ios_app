import SwiftUI

struct MainTabView: View {
    let username: String
    @Binding var showLogin: Bool
    @AppStorage("authToken") private var authToken: String = ""

    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            WelcomeView(username: username)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            Group {
                if authToken.isEmpty {
                    LoginView(showLogin: .constant(false))
                } else {
                    ChatView()
                }
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.right")
            }
            .tag(1)

            Group {
                if authToken.isEmpty {
                    LoginView(showLogin: .constant(false))
                } else {
                    PostView()
                }
            }
            .tabItem {
                Label("Post", systemImage: "plus.app")
            }
            .tag(2)

            Group {
                if authToken.isEmpty {
                    LoginView(showLogin: .constant(false))
                } else {
                    ListingsView(username: username)
                }
            }
            .tabItem {
                Label("Listings", systemImage: "list.bullet")
            }
            .tag(3)

            AccountView(username: username, showLogin: $showLogin)
                .tabItem {
                    Label("Account", systemImage: "person")
                }
                .tag(4)
        }
        // MARK: – When `selection` changes
        .onChange(of: selection, initial: false) { _, newValue in
            // If no authToken and user tries to switch away from the "Home" tab:
            if authToken.isEmpty && newValue != 0 {
                pendingSelection = newValue
                showLogin = true
                selection = 0
            }
        }
        // MARK: – When `showLogin` changes
        .onChange(of: showLogin, initial: false) { _, newValue in
            // After the login sheet is dismissed (showLogin == false), resume to pending tab if logged in:
            if !newValue,
               let pending = pendingSelection,
               !authToken.isEmpty
            {
                selection = pending
                pendingSelection = nil
            }
        }
        // MARK: – When `authToken` changes
        .onChange(of: authToken, initial: false) { _, newValue in
            // If token is cleared (user logged out) while not on Home, force them back to Home:
            if newValue.isEmpty && selection != 0 {
                pendingSelection = selection
                showLogin = true
                selection = 0
            }
        }
    }
}

#Preview {
    MainTabView(username: "daniel", showLogin: .constant(false))
}

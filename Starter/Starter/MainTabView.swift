import SwiftUI

struct MainTabView: View {
    let username: String
    @Binding var showLogin: Bool
    @AppStorage("authToken") private var authToken: String = ""

    @State private var selection = 0
    @State private var pendingSelection: Int?

    var body: some View {
        TabView(selection: $selection) {
            WelcomeView(username: username)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.right")
                }
                .tag(1)

            PostView()
                .tabItem {
                    Label("Post", systemImage: "plus.app")
                }
                .tag(2)

            ListingsView(username: username)
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
        .onChange(of: selection) { newValue in
            if authToken.isEmpty && newValue != 0 {
                pendingSelection = newValue
                showLogin = true
                selection = 0
            }
        }
        .onChange(of: showLogin) { newValue in
            if !newValue, let pending = pendingSelection, !authToken.isEmpty {
                selection = pending
                pendingSelection = nil
            }
        }
    }
}

#Preview {
    MainTabView(username: "daniel", showLogin: .constant(false))
}

import SwiftUI

struct MainTabView: View {
    let username: String
    @Binding var showLogin: Bool

    var body: some View {
        TabView {
            WelcomeView(username: username)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.right")
                }

            PostView()
                .tabItem {
                    Label("Post", systemImage: "plus.app")
                }

            ListingsView(username: username)
                .tabItem {
                    Label("Listings", systemImage: "list.bullet")
                }

            AccountView(username: username, showLogin: $showLogin)
                .tabItem {
                    Label("Account", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainTabView(username: "daniel", showLogin: .constant(false))
}

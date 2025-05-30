import SwiftUI

struct MainTabView: View {
    let username: String

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

            ListingsView()
                .tabItem {
                    Label("Listings", systemImage: "list.bullet")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainTabView(username: "User")
}

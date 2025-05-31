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
                    LoginView(showLogin: $showLogin)
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
                    LoginView(showLogin: $showLogin)
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
                    LoginView(showLogin: $showLogin)
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
    }
}

#Preview {
    MainTabView(username: "daniel", showLogin: .constant(false))
}

import SwiftUI

struct MainTabView: View {
    let username: String
    @Binding var showLogin: Bool
    @State private var selection = 0
    @State private var previousSelection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            WelcomeView(username: username)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            ChatView(showLogin: $showLogin)
                .tabItem {
                    Label("Chat", systemImage: "bubble.right")
                }
                .tag(1)
            
            PostView(showLogin: $showLogin, selection: $selection, previousSelection: $previousSelection)
                .tabItem {
                    Label("Post", systemImage: "plus.app")
                }
                .tag(2)
            
            ListingsView(username: username, showLogin: $showLogin)
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
        .onChange(of: selection, initial: false) { newValue, _ in
            if newValue != 2 {
                previousSelection = newValue
            }
        }
    }
}

#Preview {
    MainTabView(username: "daniel", showLogin: .constant(false))
}

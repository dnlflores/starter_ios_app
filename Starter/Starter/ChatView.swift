import SwiftUI

struct ChatView: View {
    /// Controls presentation of the login sheet from the parent view.
    @Binding var showLogin: Bool
    @AppStorage("authToken") private var authToken: String = ""
    @AppStorage("username") private var username: String = "Guest"
    @EnvironmentObject var chatManager: ChatManager

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
                NavigationStack {
                    List(chatManager.chats) { chat in
                        NavigationLink(destination: ChatDetailView(chatID: chat.id)) {
                            Text(chat.otherUsername)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .navigationTitle("Chats")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
        .task { chatManager.loadChats(for: username) }
    }
}

#Preview {
    ChatView(showLogin: .constant(false))
        .environmentObject(ChatManager())
}

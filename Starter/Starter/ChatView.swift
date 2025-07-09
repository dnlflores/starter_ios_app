import SwiftUI
import os

struct ChatView: View {
    /// Controls presentation of the login sheet from the parent view.
    @Binding var showLogin: Bool
    /// Controls presentation of the signup sheet from the parent view.
    @Binding var showSignUp: Bool
    @AppStorage("authToken") private var authToken: String = ""
    @AppStorage("username") private var username: String = "Guest"
    @EnvironmentObject var chatManager: ChatManager
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.starter.app", category: "ChatView")

    var body: some View {
        ZStack {
            if authToken.isEmpty {
                VStack(spacing: 16) {
                    Text("You are not logged in.")
                        .font(.title2)
                    Button("Log In") {
                        logger.info("User tapped Log In button")
                        showLogin = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    Button("Sign Up") {
                        showSignUp = true
                    }
                    .buttonStyle(.bordered)
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
    ChatView(showLogin: .constant(false), showSignUp: .constant(false))
        .environmentObject(ChatManager())
}

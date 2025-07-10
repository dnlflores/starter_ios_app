import SwiftUI

struct ChatView: View {
    /// Controls presentation of the login sheet from the parent view.
    @Binding var showLogin: Bool
    /// Controls presentation of the signup sheet from the parent view.
    @Binding var showSignUp: Bool
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
                    Button("Sign Up") {
                        showSignUp = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                }
                .padding()
            } else {
                NavigationStack {
                    VStack {
                        // WebSocket Status Indicator
                        if !chatManager.webSocketManager.isConnected {
                            HStack {
                                Image(systemName: "wifi.slash")
                                    .foregroundColor(.orange)
                                Text(chatManager.webSocketStatus)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Retry") {
                                    chatManager.reconnectWebSocket()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.yellow.opacity(0.1))
                        }
                        
                        List(chatManager.chats) { chat in
                            NavigationLink(destination: ChatDetailView(chatID: chat.id)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(chat.displayName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(chat.displaySubtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
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

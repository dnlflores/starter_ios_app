import SwiftUI

struct ChatView: View {
    /// Controls presentation of the login sheet from the parent view.
    @Binding var showLogin: Bool
    /// Controls presentation of the signup sheet from the parent view.
    @Binding var showSignUp: Bool
    @AppStorage("authToken") private var authToken: String = ""
    @AppStorage("username") private var username: String = "Guest"
    @EnvironmentObject var chatManager: ChatManager
    
    // Check if we're in preview mode
    private var isInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    // Simple default chat data for display
    private var defaultChatData: [(id: String, name: String, subtitle: String)] {
        [
            ("demo_1", "John", "General chat"),
            ("demo_2_1", "Power Drill", "with Sarah"),
            ("demo_3_2", "Lawn Mower", "with Mike")
        ]
    }
    
    // Check if we should show default data
    private var shouldShowDefaultData: Bool {
        return chatManager.chats.isEmpty
    }

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
                    VStack(spacing: 0) {
                        // Custom extended navigation header
                        VStack {
                            HStack {
                                Text("Chats")
                                    .font(.largeTitle)
                                    .foregroundColor(.purple)
                                    .bold()
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Extended black area below the title
                            Color.black
                                .frame(height: 0) // Adjust this height as needed
                        }
                        .background(Color.black)
                        
                        VStack {
                            // WebSocket Status Indicator - hide in preview mode
                            if !isInPreview && !chatManager.webSocketManager.isConnected {
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
                            
                            // Show default message when using demo data
                            if shouldShowDefaultData && !isInPreview {
                                HStack {
                                    Image(systemName: "message.circle")
                                        .foregroundColor(.blue)
                                    Text("No chats yet. Demo data shown below.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Refresh") {
                                        print("Manual refresh requested")
                                        chatManager.loadChats(for: username)
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                            }
                            
                            // Show real chats with navigation or demo data without navigation
                            if shouldShowDefaultData {
                                // Demo data (non-clickable)
                                List(defaultChatData, id: \.id) { chatData in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(chatData.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(chatData.subtitle)
                                            .font(.caption)
                                            .foregroundColor(Color.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.4))
                                            .cornerRadius(4)
                                        
                                        // Show demo indicator for default chats
                                        if !isInPreview {
                                            Text("DEMO")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                    .listRowBackground(Color.clear)
                                }
                                .padding(.top, 5)
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .applyThemeBackground()
                            } else {
                                // Real chats (clickable with navigation)
                                List(chatManager.chats) { chat in
                                    NavigationLink(value: chat.id) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(chat.displayName)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text(chat.displaySubtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                    .listRowBackground(Color.clear)
                                }
                                .padding(.top, 5)
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .applyThemeBackground()
                            }
                        }
                    }
                    .navigationBarHidden(true) // Hide the default navigation bar
                    .navigationDestination(for: String.self) { chatID in
                        ChatDetailView(chatID: chatID)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
        .task { 
            print("ChatView: Starting task - loading chats for username: \(username)")
            print("ChatView: Auth token present: \(!authToken.isEmpty)")
            chatManager.loadChats(for: username) 
        }
        .onAppear {
            print("ChatView: onAppear - Current state:")
            print("  - Username: \(username)")
            print("  - Auth token: \(authToken.isEmpty ? "Empty" : "Present")")
            print("  - Chats count: \(chatManager.chats.count)")
        }
    }
}

#Preview {
    let previewChatManager = ChatManager()
    previewChatManager.setupPreviewData()
    
    return ChatView(showLogin: .constant(false), showSignUp: .constant(false))
        .environmentObject(previewChatManager)
        .onAppear {
            UserDefaults.standard.set("daniel", forKey: "username")
        }
}

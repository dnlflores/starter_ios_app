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
    
    // Simple default chat data for display in Preview only
    private var defaultChatData: [(id: String, name: String, subtitle: String)] {
        [
            ("demo_1", "John", "General chat"),
            ("demo_2_1", "Power Drill", "with Sarah"),
            ("demo_3_2", "Lawn Mower", "with Mike")
        ]
    }
    
    // Check if we should show default data (only in Preview mode)
    private var shouldShowPreviewData: Bool {
        return isInPreview && chatManager.chats.isEmpty
    }
    
    // Check if we should show empty state (only in normal app mode)
    private var shouldShowEmptyState: Bool {
        return !isInPreview && chatManager.chats.isEmpty
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
                                Text("Chat")
                                    .font(.largeTitle)
                                    .foregroundColor(.purple)
                                    .bold()
                                Spacer()
                                
                                // Show WebSocket connection status
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(chatManager.webSocketManager.isConnected ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                    Text(chatManager.webSocketStatus)
                                        .font(.caption)
                                        .foregroundColor(Color.white)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .background(Color.black)
                        
                        // Content area
                        ZStack {
                            // Show empty state message when no chats in normal app mode
                            if shouldShowEmptyState {
                                VStack(spacing: 16) {
                                    Image(systemName: "message.circle")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    Text("No chats yet")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                    Text("Start a conversation by browsing available tools and contacting their owners.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    Button("Refresh") {
                                        print("Manual refresh requested")
                                        chatManager.loadChats(for: username)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.purple)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            // Show dummy data in Preview mode when no real chats
                            else if shouldShowPreviewData {
                                List(defaultChatData, id: \.id) { chatData in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(chatData.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(chatData.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    .listRowBackground(Color.clear)
                                }
                                .padding(.top, 5)
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                            }
                            // Show real chats with navigation
                            else {
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
                            }
                        }
                        .applyThemeBackground()
                    }
                    .navigationBarHidden(true) // Hide the default navigation bar
                    .navigationDestination(for: String.self) { chatID in
                        ChatDetailView(chatID: chatID)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(BlackPurpleBackground())
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

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(showLogin: .constant(false), showSignUp: .constant(false))
            .environmentObject(previewChatManager)
            .onAppear {
                UserDefaults.standard.set("daniel", forKey: "username")
            }
    }
    
    static var previewChatManager: ChatManager {
        let manager = ChatManager()
        manager.setupPreviewData()
        return manager
    }
}

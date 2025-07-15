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
    private var defaultChatData: [(id: String, name: String, message: String, timestamp: String, subtitle: String)] {
        [
            ("demo_1", "John", "Hey! Is the drill still available?", "6/17", "General chat"),
            ("demo_2_1", "Sarah", "Thanks for letting me borrow it", "6/15", "Power Drill"),
            ("demo_3_2", "Mike", "I'll bring it back tomorrow", "12/3/23", "Lawn Mower")
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
            // Background
            Color.white
                .ignoresSafeArea()
            
            if authToken.isEmpty {
                // Login prompt card with Airbnb-style design
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        // Icon
                        Image(systemName: "message.bubble.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        Text("Start Chatting")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Connect with tool owners and start meaningful conversations about the items you need.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            Button("Log In") {
                                showLogin = true
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            
                            Button("Sign Up") {
                                showSignUp = true
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.6))
                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .applyThemeBackground()
            } else {
                NavigationStack {
                    VStack(spacing: 0) {
                        // Airbnb-style header
                        VStack(spacing: 0) {
                            HStack {
                                Text("Messages")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Search and Settings buttons
                                HStack(spacing: 16) {
                                    Button(action: {
                                        // TODO: Implement search
                                    }) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.black)
                                            .frame(width: 44, height: 44)
                                            .background(Color.white.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                    
                                    Button(action: {
                                        // TODO: Implement settings
                                    }) {
                                        Image(systemName: "gearshape")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.black)
                                            .frame(width: 44, height: 44)
                                            .background(Color.white.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .background(Color.black)
                            
                            // Connection status indicator (smaller and more subtle)
                            if !chatManager.webSocketManager.isConnected {
                                HStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 6, height: 6)
                                    Text("Reconnecting...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            }
                        }
                        .background(Color.black)
                        
                        // Content area with Airbnb-style design
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                // Show empty state message when no chats in normal app mode
                                if shouldShowEmptyState {
                                    VStack(spacing: 24) {
                                        Spacer()
                                            .frame(height: 100)
                                        
                                        Image(systemName: "message.circle")
                                            .font(.system(size: 64))
                                            .foregroundColor(.gray.opacity(0.4))
                                        
                                        VStack(spacing: 12) {
                                            Text("No messages yet")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.black)
                                            
                                            Text("Start a conversation by browsing available tools and contacting their owners.")
                                                .font(.body)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 40)
                                        }
                                        
                                        Button("Refresh") {
                                            print("Manual refresh requested")
                                            chatManager.loadChats(for: username)
                                        }
                                        .buttonStyle(PrimaryButtonStyle())
                                        .padding(.horizontal, 80)
                                        .padding(.top, 16)
                                        
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 400)
                                }
                                // Show dummy data in Preview mode when no real chats
                                else if shouldShowPreviewData {
                                    ForEach(defaultChatData, id: \.id) { chatData in
                                        AirbnbChatRow(
                                            name: chatData.name,
                                            message: chatData.message,
                                            timestamp: chatData.timestamp,
                                            subtitle: chatData.subtitle,
                                            isPreview: true
                                        )
                                        .onTapGesture {
                                            // Preview mode - no navigation
                                        }
                                    }
                                }
                                // Show real chats with navigation
                                else {
                                    ForEach(chatManager.chats) { chat in
                                        NavigationLink(value: chat.id) {
                                            AirbnbChatRow(
                                                name: chat.displayName,
                                                message: chat.messages.last?.text ?? "No messages yet",
                                                timestamp: formatTimestamp(chat.messages.last?.date ?? Date()),
                                                subtitle: chat.displaySubtitle,
                                                isPreview: false
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .applyThemeBackground()
                    }
                    .navigationBarHidden(true)
                    .navigationDestination(for: String.self) { chatID in
                        ChatDetailView(chatID: chatID)
                    }
                }
            }
        }
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
    
    // Helper function to format timestamps
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "M/d/yy"
            return formatter.string(from: date)
        }
    }
}

// Airbnb-style chat row component
struct AirbnbChatRow: View {
    let name: String
    let message: String
    let timestamp: String
    let subtitle: String
    let isPreview: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Profile picture placeholder
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(name.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Text(timestamp)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Separator line
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
                .padding(.leading, 92) // Align with text content
        }
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(showLogin: Binding.constant(false), showSignUp: Binding.constant(false))
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

import SwiftUI

// Separate component for message bubbles
struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let username: String
    
    // Helper to format the timestamp
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .padding(8)
                        .background(Color.purple.opacity(0.7))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text(username)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTimestamp(message.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .padding(8)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text(username)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTimestamp(message.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
    }
}

struct ChatDetailView: View {
    let chatID: String
    @EnvironmentObject var chatManager: ChatManager
    @State private var messageText = ""

    private var chat: Chat? {
        chatManager.chats.first { $0.id == chatID }
    }
    
    private var chatTitle: String {
        return chat?.chatTitle ?? "Chat"
    }
    
    // Helper to get username for a sender ID
    private func getUsername(for senderId: Int) -> String {
        return chatManager.getUsername(for: senderId)
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach((chat?.messages ?? []).reversed()) { msg in
                        MessageBubbleView(
                            message: msg,
                            isCurrentUser: msg.senderId == chatManager.currentUser,
                            username: getUsername(for: msg.senderId)
                        )
                        .padding(4)
                        .id(msg.id)
                    }
                }
                .onChange(of: chat?.messages.count ?? 0) { _ in
                    if let last = chat?.messages.last {
                        proxy.scrollTo(last.id, anchor: .top)
                    }
                }
            }
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty,
                          let chat = chat else { return }
                    chatManager.send(messageText, to: chat.otherUserId, toolId: chat.toolId)
                    messageText = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding()
        }
        .navigationTitle(chatTitle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
    }
}

#Preview {
    // Create a ChatManager with sample data for preview
    let previewChatManager = ChatManager()
    
    // Set up the ChatManager with sample user and tool data
    previewChatManager.setupPreviewData()
    
    // Create sample messages
    let sampleMessages = [
        ChatMessage(
            id: 1,
            senderId: 1,
            text: "Hi! I'm interested in renting your power drill.",
            date: Date().addingTimeInterval(-3600), // 1 hour ago
            toolId: 1
        ),
        ChatMessage(
            id: 2,
            senderId: 2,
            text: "Great! It's available this weekend. $15 per day.",
            date: Date().addingTimeInterval(-3000), // 50 minutes ago
            toolId: 1
        ),
        ChatMessage(
            id: 3,
            senderId: 1,
            text: "Perfect! I'll take it for Saturday and Sunday.",
            date: Date().addingTimeInterval(-2400), // 40 minutes ago
            toolId: 1
        ),
        ChatMessage(
            id: 4,
            senderId: 2,
            text: "Sounds good! I'll have it ready for pickup on Saturday morning.",
            date: Date().addingTimeInterval(-1800), // 30 minutes ago
            toolId: 1
        )
    ]
    
    // Create sample chat with the ID expected by the preview
    let sampleChat = Chat(
        id: "1",
        otherUserId: 2,
        otherUsername: "Sarah",
        toolId: 1,
        toolName: "Power Drill",
        messages: sampleMessages
    )
    
    // Set up the ChatManager with sample data
    previewChatManager.chats = [sampleChat]
    
    return ChatDetailView(chatID: "1")
        .environmentObject(previewChatManager)
        .onAppear {
            // Set up UserDefaults for preview
            UserDefaults.standard.set("Daniel", forKey: "username")
            UserDefaults.standard.set("sample_token", forKey: "authToken")
        }
}

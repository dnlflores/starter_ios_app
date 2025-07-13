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
    ChatDetailView(chatID: "1")
        .environmentObject(ChatManager())
}

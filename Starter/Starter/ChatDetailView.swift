import SwiftUI

// Separate component for message bubbles
struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let username: String
    let onEdit: ((Int, String) -> Void)?
    
    @State private var isEditing = false
    @State private var editedText = ""
    
    // Helper to format the timestamp
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        
        if calendar.isDateInToday(date) {
            return "Today • \(timeFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday • \(timeFormatter.string(from: date))"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            return "\(dateFormatter.string(from: date)) • \(timeFormatter.string(from: date))"
        }
    }
    
    // Helper to determine if the message was edited
    private var isMessageEdited: Bool {
        return message.isEdited
    }
    
    // Helper to format timestamp with edited status
    private func formatTimestampWithEditedStatus() -> String {
        let timestamp = formatTimestamp(message.date)
        return isMessageEdited ? "\(timestamp) • Edited" : timestamp
    }
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if isEditing {
                        // Edit mode
                        HStack {
                            TextField("Edit message", text: $editedText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .dismissKeyboardOnSwipeDown()
                                .onAppear {
                                    editedText = message.text
                                }
                            
                            Button("Save") {
                                onEdit?(message.id, editedText)
                                isEditing = false
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .disabled(editedText.trimmingCharacters(in: .whitespaces).isEmpty)
                            
                            Button("Cancel") {
                                isEditing = false
                                editedText = message.text
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(8)
                        .background(Color.purple.opacity(0.7))
                        .cornerRadius(8)
                    } else {
                        // Display mode
                        Text(message.text)
                            .padding(8)
                            .background(Color.purple.opacity(0.7))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .onLongPressGesture {
                                isEditing = true
                                editedText = message.text
                            }
                    }
                    
                    Text(formatTimestampWithEditedStatus())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .padding(8)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    
                    Text(formatTimestampWithEditedStatus())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
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
            // Messages scroll view
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach((chat?.messages ?? []).reversed()) { msg in
                            MessageBubbleView(
                                message: msg,
                                isCurrentUser: msg.senderId == chatManager.currentUser,
                                username: getUsername(for: msg.senderId),
                                onEdit: { messageId, newText in
                                    chatManager.editMessage(messageId: messageId, newText: newText, in: chatID)
                                }
                            )
                            .padding(4)
                            .id(msg.id)
                        }
                    }
                }
                .onChange(of: chat?.messages.count ?? 0) { _ in
                    if let last = chat?.messages.last {
                        proxy.scrollTo(last.id, anchor: .top)
                    }
                }
            }
            
            // Message input area
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .dismissKeyboardOnSwipeDown()
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

struct ChatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ChatDetailView(chatID: "1")
            .environmentObject(previewChatManager)
            .onAppear {
                UserDefaults.standard.set("Daniel", forKey: "username")
                UserDefaults.standard.set("sample_token", forKey: "authToken")
            }
    }

    static var previewChatManager: ChatManager {
        let manager = ChatManager()
        manager.setupPreviewData()
        let sampleMessages = [
            ChatMessage(
                id: 1,
                senderId: 1,
                text: "Hi! I'm interested in renting your power drill.",
                date: Date().addingTimeInterval(-3600),
                toolId: 1,
                isEdited: false,
                updatedAt: Date().addingTimeInterval(-3600)
            ),
            ChatMessage(
                id: 2,
                senderId: 2,
                text: "Great! It's available this weekend. $15 per day.",
                date: Date().addingTimeInterval(-3000),
                toolId: 1,
                isEdited: false,
                updatedAt: Date().addingTimeInterval(-3000)
            ),
            ChatMessage(
                id: 3,
                senderId: 1,
                text: "Perfect! I'll take it for Saturday and Sunday.",
                date: Date().addingTimeInterval(-2400),
                toolId: 1,
                isEdited: false,
                updatedAt: Date().addingTimeInterval(-2400)
            ),
            ChatMessage(
                id: 4,
                senderId: 2,
                text: "Sounds good! I'll have it ready for pickup on Saturday morning.",
                date: Date().addingTimeInterval(-1800),
                toolId: 1,
                isEdited: false,
                updatedAt: Date().addingTimeInterval(-1800)
            )
        ]
        let sampleChat = Chat(
            id: "1",
            otherUserId: 2,
            otherUsername: "Sarah",
            toolId: 1,
            toolName: "Power Drill",
            messages: sampleMessages
        )
        manager.chats = [sampleChat]
        return manager
    }
}

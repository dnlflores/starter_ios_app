import SwiftUI

// MARK: - Message Bubble View
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
            dateFormatter.dateFormat = "MMM dd • "
            return "\(dateFormatter.string(from: date))\(timeFormatter.string(from: date))"
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
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    if isEditing {
                        // Edit mode with improved styling
                        VStack(spacing: 8) {
                            TextField("Edit message", text: $editedText, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundStyle(.black.opacity(0.8))
                                .padding(12)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .dismissKeyboardOnSwipeDown()
                                .onAppear {
                                    editedText = message.text
                                }
                            
                            HStack(spacing: 8) {
                                Button("Cancel") {
                                    isEditing = false
                                    editedText = message.text
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(16)
                                
                                Button("Save") {
                                    onEdit?(message.id, editedText)
                                    isEditing = false
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .disabled(editedText.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    } else {
                        // Display mode with improved styling
                        Text(message.text)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.orange)
                                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                            )
                            .onLongPressGesture {
                                isEditing = true
                                editedText = message.text
                            }
                    }
                    
                    // Timestamp with improved styling
                    HStack(spacing: 4) {
                        if isMessageEdited {
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }
                        Text(formatTimestampWithEditedStatus())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 4)
                }
            } else {
                // Other user's message
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    
                    // Timestamp with improved styling
                    HStack(spacing: 4) {
                        if isMessageEdited {
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }
                        Text(formatTimestampWithEditedStatus())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 4)
                }
                
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Chat Detail View
struct ChatDetailView: View {
    let chatID: String
    @EnvironmentObject var chatManager: ChatManager
    @State private var messageText = ""
    @FocusState private var isMessageFieldFocused: Bool

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
        VStack(spacing: 0) {
            HStack {
                Text(chatTitle)
                    .foregroundStyle(.white)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(height: 60)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 500, height: 0.5),
                alignment: .bottom
            )
            
            // Messages scroll view
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Add some top padding
                        Color.clear.frame(height: 8)
                        
                        ForEach((chat?.messages ?? []).reversed()) { msg in
                            MessageBubbleView(
                                message: msg,
                                isCurrentUser: msg.senderId == chatManager.currentUser,
                                username: getUsername(for: msg.senderId),
                                onEdit: { messageId, newText in
                                    chatManager.editMessage(messageId: messageId, newText: newText, in: chatID)
                                }
                            )
                            .id(msg.id)
                        }
                        
                        // Bottom padding for better scrolling
                        Color.clear.frame(height: 16)
                    }
                }
                .onChange(of: chat?.messages.count ?? 0) { _ in
                    if let last = chat?.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message input area with improved styling
            VStack(spacing: 12) {
                // Divider line
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                HStack(spacing: 12) {
                    // Enhanced text input
                    HStack {
                        ZStack(alignment: .leading) {
                            // Custom placeholder
                            if messageText.isEmpty {
                                Text("Type a message...")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.5))
                                    .allowsHitTesting(false)
                            }
                            
                            TextField("", text: $messageText, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white) // Typed text color
                        }
                            .focused($isMessageFieldFocused)
                            .dismissKeyboardOnSwipeDown()
                            .lineLimit(1...4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    // Send button with improved styling
                    Button(action: {
                        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty,
                              let chat = chat else { return }
                        chatManager.send(messageText, to: chat.otherUserId, toolId: chat.toolId)
                        messageText = ""
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.red]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.orange.opacity(0.4), radius: 6, x: 0, y: 3)
                            )
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(Color.black.opacity(0.1))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
        .navigationBarHidden(true)
        .onTapGesture {
            isMessageFieldFocused = false
        }
    }
}

// MARK: - Preview
struct ChatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatDetailView(chatID: "1")
                .environmentObject(previewChatManager)
                .onAppear {
                    UserDefaults.standard.set("Daniel", forKey: "username")
                    UserDefaults.standard.set("sample_token", forKey: "authToken")
                }
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
                text: "Perfect! I'll take it for Saturday and Sunday. This is a longer message to test how the bubble looks with more text content.",
                date: Date().addingTimeInterval(-2400),
                toolId: 1,
                isEdited: true,
                updatedAt: Date().addingTimeInterval(-1200)
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

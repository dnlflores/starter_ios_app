import Foundation
import SwiftUI

struct ChatMessage: Identifiable {
    let id: Int
    let senderId: Int
    let text: String
    let date: Date
    let toolId: Int?
}

struct Chat: Identifiable {
    /// The `id` corresponds to a unique identifier for the conversation.
    /// For tool-specific chats, it's constructed from user and tool IDs.
    let id: String
    let otherUserId: Int
    var otherUsername: String
    let toolId: Int?
    var toolName: String?
    var messages: [ChatMessage] = []
    
    /// Generate a unique identifier for tool-specific conversations
    static func generateId(otherUserId: Int, toolId: Int?) -> String {
        if let toolId = toolId {
            return "\(otherUserId)_\(toolId)"
        } else {
            return "\(otherUserId)"
        }
    }
}

/// Manages retrieving and sending chat messages.
final class ChatManager: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var webSocketManager = WebSocketManager()

    private var currentUserId: Int?
    private var userLookup: [Int: String] = [:]
    private let dateFormatter = ISO8601DateFormatter()

    /// Identifier of the authenticated user loaded via `loadChats`.
    var currentUser: Int? { currentUserId }
    
    init() {
        // Set up the relationship between WebSocket manager and chat manager
        webSocketManager.chatManager = self
        
        // Connect to WebSocket if user is already authenticated
        if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
            webSocketManager.connect(with: token)
        }
    }

    /// Load all chats involving the provided username from the backend.
    func loadChats(for username: String) {
        fetchUsers { [weak self] users in
            guard let self = self,
                  let me = users.first(where: { $0.username == username }) else { return }
            self.currentUserId = me.id
            self.userLookup = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0.username) })

            fetchChats { rawMessages in
                var grouped: [String: Chat] = [:]
                let relevant = rawMessages.filter { $0.sender_id == me.id || $0.recipient_id == me.id }

                for raw in relevant {
                    let otherId = raw.sender_id == me.id ? raw.recipient_id : raw.sender_id
                    let chatId = Chat.generateId(otherUserId: otherId, toolId: raw.tool_id)
                    
                    var chat = grouped[chatId] ?? Chat(
                        id: chatId,
                        otherUserId: otherId,
                        otherUsername: self.userLookup[otherId] ?? "User",
                        toolId: raw.tool_id,
                        toolName: nil, // Will be fetched from tool data if needed
                        messages: []
                    )
                    
                    let message = ChatMessage(
                        id: raw.id,
                        senderId: raw.sender_id,
                        text: raw.message,
                        date: self.dateFormatter.date(from: raw.created_at) ?? Date(),
                        toolId: raw.tool_id
                    )
                    chat.messages.append(message)
                    grouped[chatId] = chat
                }

                let sorted = grouped.values.sorted {
                    ($0.messages.last?.date ?? .distantPast) > ($1.messages.last?.date ?? .distantPast)
                }

                DispatchQueue.main.async {
                    self.chats = sorted
                    
                    // Connect to WebSocket after successful chat loading
                    if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
                        self.webSocketManager.connect(with: token)
                    }
                }
            }
        }
    }

    /// Ensure a chat exists with the specified user id, username, and tool information.
    func startChat(with otherUserId: Int, username: String, toolId: Int? = nil, toolName: String? = nil) -> Chat {
        let chatId = Chat.generateId(otherUserId: otherUserId, toolId: toolId)
        if let existing = chats.first(where: { $0.id == chatId }) {
            return existing
        }
        let chat = Chat(
            id: chatId,
            otherUserId: otherUserId,
            otherUsername: username,
            toolId: toolId,
            toolName: toolName,
            messages: []
        )
        chats.append(chat)
        return chat
    }

    /// Send a message to the given user and append it locally if successful.
    func send(_ text: String, to otherUserId: Int, toolId: Int? = nil) {
        guard let myId = currentUserId else { return }
        let token = UserDefaults.standard.string(forKey: "authToken") ?? ""
        createChatMessage(recipientId: otherUserId, message: text, toolId: toolId, authToken: token) { [weak self] created in
            guard let self = self, let created = created else { return }
            let message = ChatMessage(
                id: created.id,
                senderId: created.sender_id,
                text: created.message,
                date: self.dateFormatter.date(from: created.created_at) ?? Date(),
                toolId: created.tool_id
            )
            DispatchQueue.main.async {
                let chatId = Chat.generateId(otherUserId: otherUserId, toolId: toolId)
                if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                    self.chats[index].messages.insert(message, at: 0)
                } else {
                    let chat = Chat(
                        id: chatId,
                        otherUserId: otherUserId,
                        otherUsername: self.userLookup[otherUserId] ?? "User",
                        toolId: toolId,
                        toolName: nil,
                        messages: [message]
                    )
                    self.chats.append(chat)
                }
            }
        }
    }

    /// Retrieve chat by the other user's identifier and optional tool ID.
    func chat(with otherUserId: Int, toolId: Int? = nil) -> Chat? {
        let chatId = Chat.generateId(otherUserId: otherUserId, toolId: toolId)
        return chats.first { $0.id == chatId }
    }
    
    /// Handle real-time messages received via WebSocket
    func handleRealTimeMessage(_ apiMessage: ChatAPIMessage) {
        guard let currentUserId = currentUserId else { return }
        
        // Don't add messages we sent ourselves (they're already added when sending)
        if apiMessage.sender_id == currentUserId {
            return
        }
        
        let otherId = apiMessage.sender_id
        let chatId = Chat.generateId(otherUserId: otherId, toolId: apiMessage.tool_id)
        let message = ChatMessage(
            id: apiMessage.id,
            senderId: apiMessage.sender_id,
            text: apiMessage.message,
            date: dateFormatter.date(from: apiMessage.created_at) ?? Date(),
            toolId: apiMessage.tool_id
        )
        
        // Find existing chat or create new one
        if let chatIndex = chats.firstIndex(where: { $0.id == chatId }) {
            // Add message to existing chat and move it to the top
            chats[chatIndex].messages.insert(message, at: 0)
            let updatedChat = chats.remove(at: chatIndex)
            chats.insert(updatedChat, at: 0)
        } else {
            // Create new chat
            let otherUsername = userLookup[otherId] ?? "User"
            let newChat = Chat(
                id: chatId,
                otherUserId: otherId,
                otherUsername: otherUsername,
                toolId: apiMessage.tool_id,
                toolName: nil,
                messages: [message]
            )
            chats.insert(newChat, at: 0)
        }
    }
    
    /// Disconnect from WebSocket
    func disconnect() {
        webSocketManager.disconnect()
    }
}

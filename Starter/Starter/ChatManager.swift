import Foundation
import SwiftUI

struct ChatMessage: Identifiable {
    let id: Int
    let senderId: Int
    let text: String
    let date: Date
    let toolId: Int?
    let isEdited: Bool
    let updatedAt: Date
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
    
    /// Display name for the chat - prioritizes tool name over username
    var displayName: String {
        return toolName ?? otherUsername
    }
    
    /// Secondary information for the chat list
    var displaySubtitle: String {
        if toolName != nil {
            return "with \(otherUsername)"
        } else {
            return "General chat"
        }
    }
    
    /// Title for chat detail view
    var chatTitle: String {
        if let toolName = toolName {
            return "\(otherUsername) - \(toolName)"
        } else {
            return otherUsername
        }
    }
}

/// Manages retrieving and sending chat messages.
final class ChatManager: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var webSocketManager = WebSocketManager()

    private var currentUserId: Int?
    private var userLookup: [Int: String] = [:]
    private var toolLookup: [Int: Tool] = [:]
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
        print("ChatManager: Starting to load chats for username: \(username)")
        
        // First, fetch users
        fetchUsers { [weak self] users in
            guard let self = self else { return }
            
            print("ChatManager: Received \(users.count) users from API")
            
            guard let me = users.first(where: { $0.username == username }) else {
                print("ChatManager: Could not find user with username: \(username)")
                return
            }
            
            print("ChatManager: Found current user with ID: \(me.id)")
            self.currentUserId = me.id
            self.userLookup = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0.username) })

            // Then fetch tools and chats in parallel
            let group = DispatchGroup()
            var toolsLoaded = false
            var chatsLoaded = false
            var rawMessages: [ChatAPIMessage] = []
            
            // Fetch tools
            group.enter()
            fetchTools { tools in
                print("ChatManager: Received \(tools.count) tools from API")
                self.toolLookup = Dictionary(uniqueKeysWithValues: tools.map { ($0.id, $0) })
                toolsLoaded = true
                group.leave()
            }
            
            // Fetch chats
            group.enter()
            fetchChats { messages in
                print("ChatManager: Received \(messages.count) chat messages from API")
                rawMessages = messages
                chatsLoaded = true
                group.leave()
            }
            
            // Process chats when both are complete
            group.notify(queue: .main) {
                print("ChatManager: Both tools and chats loaded. Tools: \(toolsLoaded), Chats: \(chatsLoaded)")
                
                var grouped: [String: Chat] = [:]
                let relevant = rawMessages.filter { $0.sender_id == me.id || $0.recipient_id == me.id }
                
                print("ChatManager: Found \(relevant.count) relevant messages for current user")

                for raw in relevant {
                    let otherId = raw.sender_id == me.id ? raw.recipient_id : raw.sender_id
                    let chatId = Chat.generateId(otherUserId: otherId, toolId: raw.tool_id)
                    
                    // Get tool name from tool lookup if tool ID exists
                    let toolName = raw.tool_id.flatMap { self.toolLookup[$0]?.name }
                    
                    var chat = grouped[chatId] ?? Chat(
                        id: chatId,
                        otherUserId: otherId,
                        otherUsername: self.userLookup[otherId] ?? "User",
                        toolId: raw.tool_id,
                        toolName: toolName,
                        messages: []
                    )
                    
                    let message = ChatMessage(
                        id: raw.id,
                        senderId: raw.sender_id,
                        text: raw.message,
                        date: self.dateFormatter.date(from: raw.created_at) ?? Date(),
                        toolId: raw.tool_id,
                        isEdited: raw.is_edited,
                        updatedAt: self.dateFormatter.date(from: raw.updated_at) ?? Date()
                    )
                    chat.messages.append(message)
                    grouped[chatId] = chat
                }

                let sorted = grouped.values.sorted {
                    ($0.messages.last?.date ?? .distantPast) > ($1.messages.last?.date ?? .distantPast)
                }

                print("ChatManager: Created \(sorted.count) chat conversations")

                self.chats = sorted
                print("ChatManager: Updated UI with \(self.chats.count) chats")
                
                // Connect to WebSocket after successful chat loading
                if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
                    self.webSocketManager.connect(with: token)
                }
            }
        }
    }

    /// Ensure a chat exists with the specified user id, username, and tool information.
    func startChat(with otherUserId: Int, username: String, toolId: Int? = nil) -> Chat {
        let chatId = Chat.generateId(otherUserId: otherUserId, toolId: toolId)
        if let existing = chats.first(where: { $0.id == chatId }) {
            return existing
        }
        
        // Get tool name from tool lookup if tool ID exists
        let toolName = toolId.flatMap { toolLookup[$0]?.name }
        
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
        
        // Check WebSocket connection and attempt to reconnect if needed
        ensureWebSocketConnection()
        
        let token = UserDefaults.standard.string(forKey: "authToken") ?? ""
        createChatMessage(recipientId: otherUserId, message: text, toolId: toolId, authToken: token) { [weak self] created in
            guard let self = self, let created = created else { return }
            let message = ChatMessage(
                id: created.id,
                senderId: created.sender_id,
                text: created.message,
                date: self.dateFormatter.date(from: created.created_at) ?? Date(),
                toolId: created.tool_id,
                isEdited: created.is_edited,
                updatedAt: self.dateFormatter.date(from: created.updated_at) ?? Date()
            )
            DispatchQueue.main.async {
                let chatId = Chat.generateId(otherUserId: otherUserId, toolId: toolId)
                if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                    self.chats[index].messages.insert(message, at: 0)
                } else {
                    // Get tool name from tool lookup if tool ID exists
                    let toolName = toolId.flatMap { self.toolLookup[$0]?.name }
                    
                    let chat = Chat(
                        id: chatId,
                        otherUserId: otherUserId,
                        otherUsername: self.userLookup[otherUserId] ?? "User",
                        toolId: toolId,
                        toolName: toolName,
                        messages: [message]
                    )
                    self.chats.append(chat)
                }
            }
        }
    }
    
    /// Edit a message that was sent by the current user
    func editMessage(messageId: Int, newText: String, in chatId: String) {
        guard let currentUserId = currentUserId else { return }
        
        // Check if the message exists and belongs to the current user
        if let chatIndex = chats.firstIndex(where: { $0.id == chatId }),
           let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == messageId }),
           chats[chatIndex].messages[messageIndex].senderId == currentUserId {
            
            print("ChatManager: Editing message \(messageId) with new text: \(newText)")
            
            // For now, update the message locally
            // In a full implementation, this would make a network call to the backend
            let currentMessage = chats[chatIndex].messages[messageIndex]
            let updatedMessage = ChatMessage(
                id: currentMessage.id,
                senderId: currentMessage.senderId,
                text: newText,
                date: currentMessage.date,
                toolId: currentMessage.toolId,
                isEdited: true,
                updatedAt: Date()
            )
            
            chats[chatIndex].messages[messageIndex] = updatedMessage
            print("ChatManager: Successfully updated message \(messageId)")
            
            // TODO: Implement actual network call to backend
            // The editChatMessage function in Network.swift is ready to use
        } else {
            print("ChatManager: Message not found or not authorized to edit")
        }
    }
    
    /// Ensure WebSocket connection is active, reconnect if needed
    private func ensureWebSocketConnection() {
        if !webSocketManager.isConnected {
            if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
                print("WebSocket not connected, attempting to reconnect...")
                webSocketManager.resetAndReconnect()
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
            toolId: apiMessage.tool_id,
            isEdited: apiMessage.is_edited,
            updatedAt: dateFormatter.date(from: apiMessage.updated_at) ?? Date()
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
            // Get tool name from tool lookup if tool ID exists
            let toolName = apiMessage.tool_id.flatMap { toolLookup[$0]?.name }
            
            let newChat = Chat(
                id: chatId,
                otherUserId: otherId,
                otherUsername: otherUsername,
                toolId: apiMessage.tool_id,
                toolName: toolName,
                messages: [message]
            )
            chats.insert(newChat, at: 0)
        }
    }
    
    /// Disconnect from WebSocket
    func disconnect() {
        webSocketManager.disconnect()
    }
    
    /// Manually reconnect WebSocket (useful for debugging or user-initiated retry)
    func reconnectWebSocket() {
        if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
            print("Manual WebSocket reconnection initiated...")
            webSocketManager.resetAndReconnect()
        }
    }
    
    /// Get current WebSocket connection status
    var webSocketStatus: String {
        return webSocketManager.connectionStatus
    }
    
    /// Get username for a given user ID
    func getUsername(for userId: Int) -> String {
        return userLookup[userId] ?? "Unknown User"
    }
    
    // MARK: - Preview Support
    
    /// Set up sample data for SwiftUI previews
    func setupPreviewData() {
        // Only set up data if we're in preview mode
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" else {
            return
        }
        
        // Set up sample user data
        currentUserId = 1
        userLookup = [
            1: "Daniel",
            2: "Sarah",
            3: "Mike"
        ]
        
        // Set up sample tool data
        toolLookup = [
            1: Tool(id: 1, name: "Power Drill", price: "$15", description: "High-quality cordless drill", owner_id: 2, owner_username: "Sarah", owner_email: "sarah@example.com", owner_first_name: "Sarah", owner_last_name: "Johnson", image_url: nil, latitude: 30.2672, longitude: -97.7431),
            2: Tool(id: 2, name: "Circular Saw", price: "$25", description: "Professional-grade saw", owner_id: 3, owner_username: "Mike", owner_email: "mike@example.com", owner_first_name: "Mike", owner_last_name: "Wilson", image_url: nil, latitude: 30.2676, longitude: -97.7435)
        ]
        
        // Set up sample chat data for preview
        setupPreviewChats()
    }
    
    /// Set up sample chat conversations for preview mode
    private func setupPreviewChats() {
        // Only add dummy chats if we're in preview mode
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" else {
            return
        }
        
        // Create sample messages for different chats
        let sampleMessages1 = [
            ChatMessage(
                id: 1,
                senderId: 2,
                text: "Hi! I'm interested in renting your power drill.",
                date: Date().addingTimeInterval(-3600), // 1 hour ago
                toolId: 1,
                isEdited: false,
                updatedAt: Date()
            ),
            ChatMessage(
                id: 2,
                senderId: 1,
                text: "Great! It's available this weekend. $15 per day.",
                date: Date().addingTimeInterval(-3000), // 50 minutes ago
                toolId: 1,
                isEdited: false,
                updatedAt: Date()
            )
        ]
        
        let sampleMessages2 = [
            ChatMessage(
                id: 3,
                senderId: 3,
                text: "Is the circular saw still available?",
                date: Date().addingTimeInterval(-7200), // 2 hours ago
                toolId: 2,
                isEdited: false,
                updatedAt: Date()
            ),
            ChatMessage(
                id: 4,
                senderId: 1,
                text: "Yes, it's available. When do you need it?",
                date: Date().addingTimeInterval(-7000), // 1 hour 56 minutes ago
                toolId: 2,
                isEdited: false,
                updatedAt: Date()
            )
        ]
        
        // Create sample chats
        let sampleChats = [
            Chat(
                id: Chat.generateId(otherUserId: 2, toolId: 1),
                otherUserId: 2,
                otherUsername: "Sarah",
                toolId: 1,
                toolName: "Power Drill",
                messages: sampleMessages1
            ),
            Chat(
                id: Chat.generateId(otherUserId: 3, toolId: 2),
                otherUserId: 3,
                otherUsername: "Mike",
                toolId: 2,
                toolName: "Circular Saw",
                messages: sampleMessages2
            ),
            Chat(
                id: Chat.generateId(otherUserId: 2, toolId: nil),
                otherUserId: 2,
                otherUsername: "Sarah",
                toolId: nil,
                toolName: nil,
                messages: [
                    ChatMessage(
                        id: 5,
                        senderId: 2,
                        text: "Thanks for the great tool rental experience!",
                        date: Date().addingTimeInterval(-86400), // 1 day ago
                        toolId: nil,
                        isEdited: false,
                        updatedAt: Date()
                    )
                ]
            )
        ]
        
        // Only set the chats if we're in preview mode
        chats = sampleChats
    }
}

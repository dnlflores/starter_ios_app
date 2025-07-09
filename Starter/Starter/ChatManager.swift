import Foundation
import SwiftUI
import Combine

struct ChatMessage: Identifiable {
    let id: Int
    let senderId: Int
    let text: String
    let date: Date
}

struct Chat: Identifiable {
    /// The `id` corresponds to the other user's identifier so we can uniquely
    /// map conversations to a specific user.
    let id: Int
    let otherUserId: Int
    var otherUsername: String
    var messages: [ChatMessage] = []
}

/// Manages retrieving and sending chat messages.
final class ChatManager: ObservableObject {
    @Published var chats: [Chat] = []

    private var currentUserId: Int?
    private var userLookup: [Int: String] = [:]
    private let dateFormatter = ISO8601DateFormatter()
    private var cancellables = Set<AnyCancellable>()
    private var pollingTimer: Timer?
    private var currentUsername: String = ""

    /// Identifier of the authenticated user loaded via `loadChats`.
    var currentUser: Int? { currentUserId }

    init() {
        setupNotificationObservers()
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .newChatMessage)
            .sink { [weak self] notification in
                self?.handleNewMessageNotification(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleNewMessageNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let senderId = userInfo["sender_id"] as? Int,
              let messageText = userInfo["message"] as? String,
              let fullUserInfo = userInfo["userInfo"] as? [String: Any],
              let messageId = fullUserInfo["message_id"] as? Int,
              let createdAt = fullUserInfo["created_at"] as? String else {
            return
        }
        
        let message = ChatMessage(
            id: messageId,
            senderId: senderId,
            text: messageText,
            date: dateFormatter.date(from: createdAt) ?? Date()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.addMessageToChat(message, fromUserId: senderId)
        }
    }
    
    private func addMessageToChat(_ message: ChatMessage, fromUserId: Int) {
        if let index = chats.firstIndex(where: { $0.otherUserId == fromUserId }) {
            // Check if message already exists to avoid duplicates
            if !chats[index].messages.contains(where: { $0.id == message.id }) {
                chats[index].messages.insert(message, at: 0)
                // Move chat to top of list
                let chat = chats.remove(at: index)
                chats.insert(chat, at: 0)
            }
        } else {
            // Create new chat
            let chat = Chat(
                id: fromUserId,
                otherUserId: fromUserId,
                otherUsername: userLookup[fromUserId] ?? "User",
                messages: [message]
            )
            chats.insert(chat, at: 0)
        }
    }
    
    private func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshChats()
        }
    }
    
    private func refreshChats() {
        guard !currentUsername.isEmpty else { return }
        
        fetchChats { [weak self] rawMessages in
            guard let self = self,
                  let myId = self.currentUserId else { return }
            
            let relevant = rawMessages.filter { $0.sender_id == myId || $0.recipient_id == myId }
            var hasNewMessages = false
            
            for raw in relevant {
                let otherId = raw.sender_id == myId ? raw.recipient_id : raw.sender_id
                
                // Check if this is a new message
                if let chatIndex = self.chats.firstIndex(where: { $0.otherUserId == otherId }) {
                    if !self.chats[chatIndex].messages.contains(where: { $0.id == raw.id }) {
                        let message = ChatMessage(
                            id: raw.id,
                            senderId: raw.sender_id,
                            text: raw.message,
                            date: self.dateFormatter.date(from: raw.created_at) ?? Date()
                        )
                        DispatchQueue.main.async {
                            self.chats[chatIndex].messages.insert(message, at: 0)
                        }
                        hasNewMessages = true
                    }
                }
            }
            
            if hasNewMessages {
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }

    /// Load all chats involving the provided username from the backend.
    func loadChats(for username: String) {
        currentUsername = username
        fetchUsers { [weak self] users in
            guard let self = self,
                  let me = users.first(where: { $0.username == username }) else { return }
            self.currentUserId = me.id
            self.userLookup = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0.username) })

            fetchChats { rawMessages in
                var grouped: [Int: Chat] = [:]
                let relevant = rawMessages.filter { $0.sender_id == me.id || $0.recipient_id == me.id }

                for raw in relevant {
                    let otherId = raw.sender_id == me.id ? raw.recipient_id : raw.sender_id
                    var chat = grouped[otherId] ?? Chat(id: otherId,
                                                       otherUserId: otherId,
                                                       otherUsername: self.userLookup[otherId] ?? "User",
                                                       messages: [])
                    let message = ChatMessage(
                        id: raw.id,
                        senderId: raw.sender_id,
                        text: raw.message,
                        date: self.dateFormatter.date(from: raw.created_at) ?? Date())
                    chat.messages.append(message)
                    grouped[otherId] = chat
                }

                let sorted = grouped.values.sorted {
                    ($0.messages.last?.date ?? .distantPast) > ($1.messages.last?.date ?? .distantPast)
                }

                DispatchQueue.main.async {
                    self.chats = sorted
                    self.startPolling() // Start polling for new messages
                }
            }
        }
    }

    /// Ensure a chat exists with the specified user id and username.
    func startChat(with otherUserId: Int, username: String) -> Chat {
        if let existing = chats.first(where: { $0.otherUserId == otherUserId }) {
            return existing
        }
        let chat = Chat(id: otherUserId, otherUserId: otherUserId, otherUsername: username, messages: [])
        chats.append(chat)
        return chat
    }

    /// Send a message to the given user and append it locally if successful.
    func send(_ text: String, to otherUserId: Int) {
        guard let myId = currentUserId else { return }
        let token = UserDefaults.standard.string(forKey: "authToken") ?? ""
        createChatMessage(recipientId: otherUserId, message: text, authToken: token) { [weak self] created in
            guard let self = self, let created = created else { return }
            let message = ChatMessage(
                id: created.id,
                senderId: created.sender_id,
                text: created.message,
                date: self.dateFormatter.date(from: created.created_at) ?? Date())
            DispatchQueue.main.async {
                if let index = self.chats.firstIndex(where: { $0.otherUserId == otherUserId }) {
                    self.chats[index].messages.insert(message, at: 0)
                } else {
                    let chat = Chat(id: otherUserId,
                                    otherUserId: otherUserId,
                                    otherUsername: self.userLookup[otherUserId] ?? "User",
                                    messages: [message])
                    self.chats.append(chat)
                }
            }
        }
    }

    /// Retrieve chat by the other user's identifier.
    func chat(with otherUserId: Int) -> Chat? {
        chats.first { $0.otherUserId == otherUserId }
    }
}

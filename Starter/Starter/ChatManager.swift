import Foundation
import SwiftUI

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

    /// Identifier of the authenticated user loaded via `loadChats`.
    var currentUser: Int? { currentUserId }

    /// Load all chats involving the provided username from the backend.
    func loadChats(for username: String) {
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

//
//  Network.swift
//  Starter
//
//  Created by Daniel Flores on 5/30/25.
//

import Foundation

struct AuthResponse: Codable {
    let token: String
}

struct User: Codable {
    let id: Int
    let username: String
    let email: String?
    let created_at: String?
    let updated_at: String?
    let is_seller: Bool?
    let is_admin: Bool?
    let first_name: String?
    let last_name: String?
    let phone: String?
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
}

struct Tool: Codable, Identifiable {
    let id: Int
    let name: String
    let price: String
    let description: String?
    let owner_id: Int?
    let owner_username: String?
    let owner_email: String?
    let owner_first_name: String?
    let owner_last_name: String?
}

func signup(username: String, email: String, password: String, street: String, city: String, state: String, zip: String, phone: String, completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: "https://starter-ios-app-backend.onrender.com/signup") else { completion(false); return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "username": username,
        "email": email,
        "password": password,
        "address": street,
        "city": city,
        "state": state,
        "zip": zip,
        "phone": phone
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { _, response, _ in
        if let http = response as? HTTPURLResponse, http.statusCode == 201 {
            completion(true)
        } else {
            completion(false)
        }
    }.resume()
}

func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: "https://starter-ios-app-backend.onrender.com/login") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["username": username, "password": password]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data,
           let auth = try? JSONDecoder().decode(AuthResponse.self, from: data) {
            UserDefaults.standard.set(auth.token, forKey: "authToken")
            UserDefaults.standard.set(username, forKey: "username")
            print("Login success, token: \(auth.token)")
            completion(true)
        } else {
            completion(false)
        }
    }.resume()
}

func fetchUsers(completion: @escaping ([User]) -> Void) {
    guard let token = UserDefaults.standard.string(forKey: "authToken"),
          let url = URL(string: "https://starter-ios-app-backend.onrender.com/users") else {
        print("Network: fetchUsers failed - missing token or invalid URL")
        completion([])
        return
    }

    print("Network: Fetching users from API...")
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Network: fetchUsers failed with error: \(error.localizedDescription)")
            completion([])
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Network: fetchUsers response code: \(httpResponse.statusCode)")
        }
        
        if let data = data {
            print("Network: fetchUsers received \(data.count) bytes of data")
            if let users = try? JSONDecoder().decode([User].self, from: data) {
                print("Network: Successfully decoded \(users.count) users")
                completion(users)
            } else {
                print("Network: Failed to decode users JSON")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Network: Raw JSON: \(jsonString)")
                }
                completion([])
            }
        } else {
            print("Network: fetchUsers received no data")
            completion([])
        }
    }.resume()
}

func fetchTools(completion: @escaping ([Tool]) -> Void) {
    guard let url = URL(string: "https://starter-ios-app-backend.onrender.com/tools") else {
        print("Network: fetchTools failed - invalid URL")
        completion([])
        return
    }

    print("Network: Fetching tools from API...")
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Network: fetchTools failed with error: \(error.localizedDescription)")
            completion([])
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Network: fetchTools response code: \(httpResponse.statusCode)")
        }
        
        if let data = data {
            print("Network: fetchTools received \(data.count) bytes of data")
            if let tools = try? JSONDecoder().decode([Tool].self, from: data) {
                print("Network: Successfully decoded \(tools.count) tools")
                completion(tools)
            } else {
                print("Network: Failed to decode tools JSON")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Network: Raw JSON: \(jsonString)")
                }
                completion([])
            }
        } else {
            print("Network: fetchTools received no data")
            completion([])
        }
    }.resume()
}

/// Clear the stored authentication token and user information.
func logout(chatManager: ChatManager? = nil) {
    UserDefaults.standard.removeObject(forKey: "authToken")
    UserDefaults.standard.removeObject(forKey: "username")
    
    // Disconnect from WebSocket
    chatManager?.disconnect()
}

/// Create a new tool on the server.
func createTool(name: String, price: Double, description: String, ownerId: Int, createdAt: String, authToken: String, completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: "https://starter-ios-app-backend.onrender.com/tools") else {
        completion(false)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    let body: [String: Any] = [
        "name": name,
        "price": price,
        "description": description,
        "owner_id": ownerId,
        "created_at": createdAt
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { _, response, _ in
        if let http = response as? HTTPURLResponse, http.statusCode == 201 {
            completion(true)
        } else {
            completion(false)
        }
    }.resume()
}

// Model for basic chat message (used for POST responses)
struct ChatAPIMessage: Codable, Identifiable {
    let id: Int
    let sender_id: Int
    let recipient_id: Int
    let tool_id: Int?
    let message: String
    let image_url: String?
    let is_edited: Bool
    let created_at: String
    let updated_at: String
    let edited_at: String?
    
    // Custom initializer to handle potential nil values from database defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        sender_id = try container.decode(Int.self, forKey: .sender_id)
        recipient_id = try container.decode(Int.self, forKey: .recipient_id)
        tool_id = try container.decodeIfPresent(Int.self, forKey: .tool_id)
        message = try container.decode(String.self, forKey: .message)
        image_url = try container.decodeIfPresent(String.self, forKey: .image_url)
        is_edited = try container.decodeIfPresent(Bool.self, forKey: .is_edited) ?? false
        created_at = try container.decode(String.self, forKey: .created_at)
        updated_at = try container.decodeIfPresent(String.self, forKey: .updated_at) ?? created_at
        edited_at = try container.decodeIfPresent(String.self, forKey: .edited_at)
    }
    
    // Default memberwise initializer for creating instances
    init(id: Int, sender_id: Int, recipient_id: Int, tool_id: Int? = nil, message: String, image_url: String? = nil, is_edited: Bool = false, created_at: String, updated_at: String, edited_at: String? = nil) {
        self.id = id
        self.sender_id = sender_id
        self.recipient_id = recipient_id
        self.tool_id = tool_id
        self.message = message
        self.image_url = image_url
        self.is_edited = is_edited
        self.created_at = created_at
        self.updated_at = updated_at
        self.edited_at = edited_at
    }
}

// Model for detailed chat message with user info (used for GET responses)
struct DetailedChatAPIMessage: Codable, Identifiable {
    let id: Int
    let sender_id: Int
    let recipient_id: Int
    let tool_id: Int?
    let message: String
    let image_url: String?
    let is_edited: Bool
    let created_at: String
    let updated_at: String
    let edited_at: String?
    let sender_username: String?
    let sender_first_name: String?
    let sender_last_name: String?
    let recipient_username: String?
    let recipient_first_name: String?
    let recipient_last_name: String?
    let tool_name: String?
    let tool_description: String?
    
    // Custom initializer to handle potential nil values from database defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        sender_id = try container.decode(Int.self, forKey: .sender_id)
        recipient_id = try container.decode(Int.self, forKey: .recipient_id)
        tool_id = try container.decodeIfPresent(Int.self, forKey: .tool_id)
        message = try container.decode(String.self, forKey: .message)
        image_url = try container.decodeIfPresent(String.self, forKey: .image_url)
        is_edited = try container.decodeIfPresent(Bool.self, forKey: .is_edited) ?? false
        created_at = try container.decode(String.self, forKey: .created_at)
        updated_at = try container.decodeIfPresent(String.self, forKey: .updated_at) ?? created_at
        edited_at = try container.decodeIfPresent(String.self, forKey: .edited_at)
        sender_username = try container.decodeIfPresent(String.self, forKey: .sender_username)
        sender_first_name = try container.decodeIfPresent(String.self, forKey: .sender_first_name)
        sender_last_name = try container.decodeIfPresent(String.self, forKey: .sender_last_name)
        recipient_username = try container.decodeIfPresent(String.self, forKey: .recipient_username)
        recipient_first_name = try container.decodeIfPresent(String.self, forKey: .recipient_first_name)
        recipient_last_name = try container.decodeIfPresent(String.self, forKey: .recipient_last_name)
        tool_name = try container.decodeIfPresent(String.self, forKey: .tool_name)
        tool_description = try container.decodeIfPresent(String.self, forKey: .tool_description)
    }
}

/// Retrieve all chat messages from the server.
func fetchChats(completion: @escaping ([ChatAPIMessage]) -> Void) {
    guard let url = URL(string: "https://starter-ios-app-backend.onrender.com/chats") else {
        print("Network: fetchChats failed - invalid URL")
        completion([])
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    guard let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty else {
        print("Network: fetchChats failed - no auth token available")
        completion([])
        return
    }
    
    print("Network: Fetching chats from API...")
    
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Network: fetchChats failed with error: \(error.localizedDescription)")
            completion([])
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Network: fetchChats response code: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    print("Network: fetchChats error response: \(errorString)")
                }
                completion([])
                return
            }
        }
        
        if let data = data {
            print("Network: fetchChats received \(data.count) bytes of data")
            
            // First try to decode as detailed messages (GET response)
            if let detailedChats = try? JSONDecoder().decode([DetailedChatAPIMessage].self, from: data) {
                print("Network: Successfully decoded \(detailedChats.count) detailed chat messages")
                
                // Convert to simple ChatAPIMessage format
                let simpleChats = detailedChats.map { detailed in
                    ChatAPIMessage(
                        id: detailed.id,
                        sender_id: detailed.sender_id,
                        recipient_id: detailed.recipient_id,
                        tool_id: detailed.tool_id,
                        message: detailed.message,
                        image_url: detailed.image_url,
                        is_edited: detailed.is_edited,
                        created_at: detailed.created_at,
                        updated_at: detailed.updated_at,
                        edited_at: detailed.edited_at
                    )
                }
                completion(simpleChats)
            } else if let chats = try? JSONDecoder().decode([ChatAPIMessage].self, from: data) {
                print("Network: Successfully decoded \(chats.count) simple chat messages")
                completion(chats)
            } else {
                print("Network: Failed to decode chat messages from response")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Network: Raw JSON: \(jsonString)")
                }
                completion([])
            }
        } else {
            print("Network: fetchChats received no data")
            completion([])
        }
    }.resume()
}

/// Post a new chat message.
func createChatMessage(recipientId: Int, message: String, toolId: Int? = nil, authToken: String, completion: @escaping (ChatAPIMessage?) -> Void) {
    guard let url = URL(string: "https://starter-ios-app-backend.onrender.com/chats") else {
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    var body: [String: Any] = [
        "recipient_id": recipientId,
        "message": message
    ]
    
    if let toolId = toolId {
        body["tool_id"] = toolId
    }
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Network error: \(error)")
            completion(nil)
            return
        }
        
        if let data = data {
            if let chat = try? JSONDecoder().decode(ChatAPIMessage.self, from: data) {
                completion(chat)
            } else {
                print("Failed to decode ChatAPIMessage")
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }.resume()
}

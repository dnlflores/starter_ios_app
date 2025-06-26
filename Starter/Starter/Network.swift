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
    let latitude: Double?
    let longitude: Double?
}

func signup(username: String, password: String) {
    guard let url = URL(string: "https://starter-ios-app-backend.onrender.com/signup") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["username": username, "password": password]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request).resume()
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
        completion([])
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request) { data, _, _ in
        if let data = data,
           let users = try? JSONDecoder().decode([User].self, from: data) {
            completion(users)
        } else {
            completion([])
        }
    }.resume()
}

func fetchTools(completion: @escaping ([Tool]) -> Void) {
    guard let url = URL(string: "https://starter-ios-app-backend.onrender.com/tools") else {
        completion([])
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    URLSession.shared.dataTask(with: request) { data, _, _ in
        if let data = data,
           let tools = try? JSONDecoder().decode([Tool].self, from: data) {
            completion(tools)
        } else {
            completion([])
        }
    }.resume()
}

/// Clear the stored authentication token and user information.
func logout() {
    UserDefaults.standard.removeObject(forKey: "authToken")
    UserDefaults.standard.removeObject(forKey: "username")
}

/// Create a new tool on the server.
func createTool(
    name: String,
    price: Double,
    description: String,
    ownerId: Int,
    createdAt: String,
    latitude: Double,
    longitude: Double,
    authToken: String,
    completion: @escaping (Bool) -> Void
) {
    let baseURL = "https://starter-ios-app-backend.onrender.com/tools"

    let body: [String: Any] = [
        "name": name,
        "price": price,
        "description": description,
        "owner_id": ownerId,
        "created_at": createdAt,
        "latitude": latitude,
        "longitude": longitude
    ]

    guard let checkURL = URL(string: "\(baseURL)/name/\(name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name)") else {
        completion(false)
        return
    }

    // First check if a tool with the same name exists
    URLSession.shared.dataTask(with: checkURL) { data, response, _ in
        if let http = response as? HTTPURLResponse, http.statusCode == 200,
           let data = data,
           let existingTool = try? JSONDecoder().decode(Tool.self, from: data) {
            // Tool exists, update it
            guard let url = URL(string: "\(baseURL)/\(existingTool.id)") else {
                completion(false)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            URLSession.shared.dataTask(with: request) { _, response, _ in
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    completion(true)
                } else {
                    completion(false)
                }
            }.resume()
        } else {
            // Tool does not exist, create a new one
            guard let url = URL(string: baseURL) else {
                completion(false)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { _, response, _ in
                if let http = response as? HTTPURLResponse, http.statusCode == 201 {
                    completion(true)
                } else {
                    completion(false)
                }
            }.resume()
        }
    }.resume()
}

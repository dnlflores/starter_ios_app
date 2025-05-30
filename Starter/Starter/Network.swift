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
}

func signup(username: String, password: String) {
    guard let url = URL(string: "https://8115-69-244-64-109.ngrok-free.app/signup") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["username": username, "password": password]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request).resume()
}

func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: "https://8115-69-244-64-109.ngrok-free.app/login") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["username": username, "password": password]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data,
           let auth = try? JSONDecoder().decode(AuthResponse.self, from: data) {
            UserDefaults.standard.set(auth.token, forKey: "authToken")
            print("Login success, token: \(auth.token)")
            completion(true)
        } else {
            completion(false)
        }
    }.resume()
}

func fetchUsers() {
    guard let token = UserDefaults.standard.string(forKey: "authToken"),
          let url = URL(string: "https://8115-69-244-64-109.ngrok-free.app/users") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request) { data, _, _ in
        if let data = data,
           let users = try? JSONDecoder().decode([User].self, from: data) {
            print("Fetched users: \(users)")
        }
    }.resume()
}

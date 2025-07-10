import Foundation
import SwiftUI

class WebSocketManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let baseURL = "wss://starter-ios-app-backend.onrender.com/ws"
    private var authToken: String?
    private var pingTimer: Timer?
    
    weak var chatManager: ChatManager?
    
    override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    func connect(with token: String) {
        guard let url = URL(string: baseURL) else {
            print("Invalid WebSocket URL")
            return
        }
        
        self.authToken = token
        
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = urlSession?.webSocketTask(with: url)
        webSocket?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        // Send authentication message
        authenticate()
        
        // Start ping timer for connection health
        startPingTimer()
        
        DispatchQueue.main.async {
            self.connectionStatus = "Connecting..."
        }
    }
    
    func disconnect() {
        stopPingTimer()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Disconnected"
        }
    }
    
    private func authenticate() {
        guard let token = authToken else { return }
        
        let authMessage = [
            "type": "auth",
            "token": token
        ]
        
        sendMessage(authMessage)
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard let webSocket = webSocket else { return }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            let message = URLSessionWebSocketTask.Message.data(data)
            webSocket.send(message) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                }
            }
        } catch {
            print("Error serializing WebSocket message: \(error)")
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue listening for messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.connectionStatus = "Connection Error"
                }
                // Try to reconnect after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.reconnect()
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("Invalid WebSocket message format")
            return
        }
        
        DispatchQueue.main.async {
            switch type {
            case "auth_success":
                self.isConnected = true
                self.connectionStatus = "Connected"
                print("WebSocket authenticated successfully")
                
            case "auth_error":
                self.isConnected = false
                self.connectionStatus = "Authentication Failed"
                print("WebSocket authentication failed")
                
            case "new_message":
                self.handleNewMessage(json)
                
            case "pong":
                // Connection is alive
                break
                
            case "error":
                if let message = json["message"] as? String {
                    print("WebSocket error: \(message)")
                }
                
            default:
                print("Unknown WebSocket message type: \(type)")
            }
        }
    }
    
    private func handleNewMessage(_ json: [String: Any]) {
        guard let messageData = json["data"] as? [String: Any] else {
            print("Invalid new message data")
            return
        }
        
        // Parse the message data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let chatMessage = try JSONDecoder().decode(ChatAPIMessage.self, from: jsonData)
            
            // Notify the chat manager about the new message
            chatManager?.handleRealTimeMessage(chatMessage)
            
        } catch {
            print("Error parsing real-time message: \(error)")
        }
    }
    
    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        let pingMessage = ["type": "ping"]
        sendMessage(pingMessage)
    }
    
    private func reconnect() {
        guard let token = authToken else { return }
        connect(with: token)
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Disconnected"
        }
    }
}

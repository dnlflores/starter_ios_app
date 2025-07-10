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
    private var reconnectTimer: Timer?
    
    // Connection state management
    private var isConnecting = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var reconnectDelay: TimeInterval = 1.0
    private let maxReconnectDelay: TimeInterval = 30.0
    
    weak var chatManager: ChatManager?
    
    override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    func connect(with token: String) {
        // Prevent multiple concurrent connections
        guard !isConnecting else {
            print("WebSocket connection already in progress")
            return
        }
        
        guard let url = URL(string: baseURL) else {
            print("Invalid WebSocket URL")
            return
        }
        
        isConnecting = true
        self.authToken = token
        
        // Cancel any existing connection and timers
        stopReconnectTimer()
        webSocket?.cancel(with: .goingAway, reason: nil)
        
        webSocket = urlSession?.webSocketTask(with: url)
        webSocket?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        // Send authentication message
        authenticate()
        
        DispatchQueue.main.async {
            self.connectionStatus = "Connecting..."
        }
        
        print("WebSocket connecting to \(baseURL)")
    }
    
    func disconnect() {
        print("WebSocket disconnecting...")
        
        // Clean up all state and timers
        stopPingTimer()
        stopReconnectTimer()
        
        isConnecting = false
        reconnectAttempts = 0
        reconnectDelay = 1.0
        
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
                self?.handleReceiveError(error)
            }
        }
    }
    
    private func handleReceiveError(_ error: Error) {
        print("WebSocket receive error: \(error)")
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.isConnecting = false
        }
        
        // Don't reconnect for certain error types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                print("WebSocket connection was cancelled - not reconnecting")
                DispatchQueue.main.async {
                    self.connectionStatus = "Disconnected"
                }
                return
            case .networkConnectionLost, .notConnectedToInternet:
                print("Network connectivity issue - will retry with exponential backoff")
            case .timedOut:
                print("Connection timed out - will retry")
            default:
                print("WebSocket error: \(urlError.localizedDescription)")
            }
        }
        
        // Check if we should attempt to reconnect
        if reconnectAttempts < maxReconnectAttempts {
            scheduleReconnect()
        } else {
            DispatchQueue.main.async {
                self.connectionStatus = "Connection Failed - Max Retries Exceeded"
            }
            print("Max reconnection attempts reached. Stopping reconnection attempts.")
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
                self.isConnecting = false
                self.connectionStatus = "Connected"
                
                // Reset reconnection state on successful connection
                self.reconnectAttempts = 0
                self.reconnectDelay = 1.0
                
                // Start ping timer for connection health
                self.startPingTimer()
                
                print("WebSocket authenticated successfully")
                
            case "auth_error":
                self.isConnected = false
                self.isConnecting = false
                self.connectionStatus = "Authentication Failed"
                print("WebSocket authentication failed")
                
            case "new_message":
                self.handleNewMessage(json)
                
            case "pong":
                // Connection is alive
                print("WebSocket pong received")
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
        // Increase ping interval to reduce server load
        pingTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
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
    
    private func scheduleReconnect() {
        stopReconnectTimer()
        
        reconnectAttempts += 1
        
        DispatchQueue.main.async {
            self.connectionStatus = "Reconnecting... (Attempt \(self.reconnectAttempts)/\(self.maxReconnectAttempts))"
        }
        
        print("Scheduling reconnection attempt \(reconnectAttempts) in \(reconnectDelay) seconds")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, repeats: false) { [weak self] _ in
            self?.reconnect()
        }
        
        // Exponential backoff with jitter
        reconnectDelay = min(reconnectDelay * 2 + Double.random(in: 0...1), maxReconnectDelay)
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func reconnect() {
        guard let token = authToken else { return }
        print("Attempting to reconnect...")
        connect(with: token)
    }
    
    /// Reset connection state and attempt to reconnect immediately
    func resetAndReconnect() {
        print("Resetting WebSocket connection state...")
        reconnectAttempts = 0
        reconnectDelay = 1.0
        
        if let token = authToken {
            connect(with: token)
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connection opened")
        // Don't set isConnected here - wait for authentication success
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown"
        print("WebSocket connection closed with code: \(closeCode.rawValue), reason: \(reasonString)")
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.isConnecting = false
            
            // Only attempt reconnection if this wasn't a manual disconnect
            if closeCode != .goingAway && self.reconnectAttempts < self.maxReconnectAttempts {
                self.scheduleReconnect()
            } else {
                self.connectionStatus = "Disconnected"
            }
        }
    }
}

import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func registerDeviceToken() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // Send device token to your backend
    func sendDeviceTokenToServer(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        guard let url = URL(string: "https://starter-ios-app-backend.onrender.com/device-token"),
              let token = UserDefaults.standard.string(forKey: "authToken") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["device_token": tokenString]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Failed to send device token: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Device token sent with status: \(httpResponse.statusCode)")
            }
        }.resume()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Extract chat info from notification
        let userInfo = notification.request.content.userInfo
        if let senderId = userInfo["sender_id"] as? Int,
           let message = userInfo["message"] as? String {
            
            // Post notification to update chat if user is viewing it
            NotificationCenter.default.post(name: .newChatMessage, object: nil, userInfo: [
                "sender_id": senderId,
                "message": message,
                "userInfo": userInfo
            ])
        }
        
        // Show notification banner, badge, and sound
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        if let senderId = userInfo["sender_id"] as? Int {
            // Navigate to chat
            NotificationCenter.default.post(name: .navigateToChat, object: nil, userInfo: ["sender_id": senderId])
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newChatMessage = Notification.Name("newChatMessage")
    static let navigateToChat = Notification.Name("navigateToChat")
}

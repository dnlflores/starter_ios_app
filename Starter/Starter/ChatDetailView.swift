import SwiftUI

struct ChatDetailView: View {
    let chatID: String
    @EnvironmentObject var chatManager: ChatManager
    @State private var messageText = ""

    private var chat: Chat? {
        chatManager.chats.first { $0.id == chatID }
    }
    
    private var chatTitle: String {
        guard let chat = chat else { return "Chat" }
        if let toolName = chat.toolName {
            return "\(chat.otherUsername) - \(toolName)"
        } else {
            return chat.otherUsername
        }
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach((chat?.messages ?? []).reversed()) { msg in
                        HStack {
                            if msg.senderId == chatManager.currentUser {
                                Spacer()
                                Text(msg.text)
                                    .padding(8)
                                    .background(Color.purple.opacity(0.7))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            } else {
                                Text(msg.text)
                                    .padding(8)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .padding(4)
                        .id(msg.id)
                    }
                }
                .onChange(of: chat?.messages.count ?? 0) { _ in
                    if let last = chat?.messages.last {
                        proxy.scrollTo(last.id, anchor: .top)
                    }
                }
            }
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty,
                          let chat = chat else { return }
                    chatManager.send(messageText, to: chat.otherUserId, toolId: chat.toolId)
                    messageText = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding()
        }
        .navigationTitle(chatTitle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
    }
}

#Preview {
    ChatDetailView(chatID: "1")
        .environmentObject(ChatManager())
}

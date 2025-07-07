import SwiftUI

struct ChatDetailView: View {
    let chatID: Int
    @EnvironmentObject var chatManager: ChatManager
    @State private var messageText = ""

    private var chat: Chat? {
        chatManager.chat(with: chatID)
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(chat?.messages ?? []) { msg in
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
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    chatManager.send(messageText, to: chatID)
                    messageText = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding()
        }
        .navigationTitle(chat?.otherUsername ?? "Chat")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
    }
}

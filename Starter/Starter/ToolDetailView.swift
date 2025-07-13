import SwiftUI

struct ToolDetailView: View {
    let tool: Tool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var chatManager: ChatManager
    @State private var showChat = false
    @State private var startedChatID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(tool.description ?? "No description available")
                Text("Price per hour: \(tool.price)")
                if let ownerFirst = tool.owner_first_name, let ownerLast = tool.owner_last_name {
                    Text("Owner: \(ownerFirst) \(ownerLast)")
                }
                if let ownerEmail = tool.owner_email {
                    Text("Email: \(ownerEmail)")
                }

                MapView()
                    .frame(height: 200)
                    .cornerRadius(20)

                Button(action: {
                    let chat = chatManager.startChat(
                        with: tool.owner_id ?? 0,
                        username: tool.owner_username ?? "User",
                        toolId: tool.id
                    )
                    startedChatID = chat.id
                    showChat = true
                }) {
                    Text("Start Chat")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                }
                .font(.title2)
                .background(Color.black.opacity(0.4))
                .shadow(radius: 8)
                .cornerRadius(8)
                .foregroundColor(.white)
                .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
        .background(
            NavigationLink(destination: ChatDetailView(chatID: startedChatID ?? ""), isActive: $showChat) { EmptyView() }
                .hidden()
        )
        .applyThemeBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                Text(tool.name)
                    .foregroundStyle(.purple)
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(Color.black, for: .tabBar)
        .tint(.purple)
    }
}

#Preview {
    let previewChatManager = ChatManager()
    previewChatManager.setupPreviewData()
    
    return ToolDetailView(tool: Tool(id: 1, name: "Hammer", price: "$10", description: "A sturdy hammer.", owner_id: 1, owner_username: "johndoe", owner_email: "johndoe@example.com", owner_first_name: "John", owner_last_name: "Doe"))
        .environmentObject(previewChatManager)
}

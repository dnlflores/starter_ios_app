import SwiftUI

struct ToolDetailView: View {
    let tool: Tool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var chatManager: ChatManager
    @State private var showChat = false
    @State private var startedChatID: String?

    var body: some View {
        ScrollView {
            ZStack {
                Text(tool.name)
                    .font(.title)
                    .padding()
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
            }
            .frame(width: UIScreen.main.bounds.width - 30)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
                    .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 4)
            )
            .padding(.top, 25)
            VStack(alignment: .leading, spacing: 16) {
                Text("Description")
                    .font(.system(size: 14, weight: .bold))
                ZStack {
                    Text(tool.description ?? "No description available")
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .padding()
                        .foregroundStyle(.white)
                }
                .frame(width: UIScreen.main.bounds.width - 30)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                        .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 4)
                )
                HStack {
                    HStack (spacing: 0) {
                        Text("$\(tool.price)")
                            .font(.system(size: 26))
                            .padding(0)
                            .foregroundColor(Color.green)
                        VStack {
                            Text("Per")
                                .padding(.top, 4)
                                .font(.system(size: 8))
                                .foregroundColor(Color.green)
                            Text("Day")
                                .padding(.bottom, 4)
                                .font(.system(size: 8))
                                .foregroundColor(Color.green)
                        }
                        .padding(.leading, 3)
                    }
                        .padding()
                        .background(Color.green.opacity(0.3).cornerRadius(10))
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
                    Spacer()
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        Text("\(tool.owner_first_name ?? "Unknown") \(tool.owner_last_name ?? "User")")
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.4))
                            .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 4)
                    )
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
                        .padding(10)
                        .fontWeight(.bold)
                    Image(systemName: "bubble.fill")
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.4))
                        .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 4)
                )
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
                Button(action: { dismiss() }) {
                    HStack {
                        Text("RNTL")
                            .fontWeight(.bold)
                            .font(.title)
                    }
                    .padding(.bottom, 5)
                }
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(Color.black, for: .tabBar)
        .tint(.red)
    }
}

#Preview {
    let previewChatManager = ChatManager()
    previewChatManager.setupPreviewData()
    
    return ToolDetailView(tool: Tool(id: 1, name: "Professional Claw Hammer 25 ", price: "10", description: "Heavy-duty 25-foot tape measure with standout up to 7 feet for one-person measuring. Features a durable nylon-coated steel blade with clear, easy-to-read markings in both imperial and metric units. The True Zero end hook moves in and out for inside and outside measurements. Cushioned case design withstands 10-foot drops. Belt clip attachment for convenient carrying. Blade width: 1 inch. Includes fraction markings down to 1/16 inch for precise measurements. Perfect for construction, home improvement, and professional contracting work.", owner_id: 1, owner_username: "johndoe", owner_email: "johndoe@example.com", owner_first_name: "John", owner_last_name: "Doe"))
        .environmentObject(previewChatManager)
}

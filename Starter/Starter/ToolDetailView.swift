import SwiftUI

struct ToolDetailView: View {
    let tool: Tool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var chatManager: ChatManager
    @State private var showChat = false
    @State private var startedChatID: String?
    
    private var formattedPrice: String {
        guard let price = Double(tool.price) else {
            return tool.price // Return original string if conversion fails
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: price)) ?? tool.price
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image Section
                GeometryReader { geometry in
                    ZStack {
                        if let imageUrl = tool.image_url, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                            Text("Loading...")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                    )
                            }
                        } else {
                            Rectangle()
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    VStack {
                                        Image(systemName: "wrench.and.screwdriver")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                        Text("No Image")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                )
                        }
                        
                        // Gradient overlay for better text readability
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.4)]),
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    }
                }
                .frame(height: 300)
                .cornerRadius(0)
                
                // Content Section
                VStack(alignment: .leading, spacing: 24) {
                    // Title and Price Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tool.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        HStack {
                            Text("$\(formattedPrice)")
                                .font(.system(size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("per day")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                        }
                    }
                    
                    Divider()
                        .background(Color.white)
                    
                    // Host Information
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Owned by")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(tool.owner_first_name ?? "Unknown") \(tool.owner_last_name ?? "User")")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color.white)
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About this tool")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(tool.description ?? "No description available")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    // Location Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Where you'll pick up")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        MapView()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Spacer(minLength: 100) // Space for bottom bar
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .ignoresSafeArea(edges: .top)
        .overlay(
            // Floating bottom bar
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("$\(formattedPrice)")
                                    .font(.system(size: 26))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                VStack {
                                    Text("per")
                                        .font(.system(size: 12))
                                    Text("day")
                                        .font(.system(size: 12))
                                }
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            }
                            .frame(maxWidth: 120)
                            Text("Available now")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            let chat = chatManager.startChat(
                                with: tool.owner_id ?? 0,
                                username: tool.owner_username ?? "User",
                                toolId: tool.id
                            )
                            startedChatID = chat.id
                            showChat = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "message")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Contact Owner")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                            .frame(width: 150)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.orange]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.black)
                }
            }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(Color.black, for: .tabBar)
        .background(
            NavigationLink(destination: ChatDetailView(chatID: startedChatID ?? ""), isActive: $showChat) { EmptyView() }
                .hidden()
        )
        .applyThemeBackground()
    }
}

#Preview {
    Group {
        let previewChatManager = ChatManager()
        let _ = previewChatManager.setupPreviewData()
        
        ToolDetailView(tool: Tool(
            id: 1, 
            name: "Professional Drill Set", 
            price: "7",
            description: "High-quality professional drill set with multiple bits and accessories. Perfect for home improvement projects, furniture assembly, and general construction work. Includes cordless drill, impact driver, and a comprehensive bit set. Battery included with 2-hour fast charging capability.",
            owner_id: 1, 
            owner_username: "johndoe", 
            owner_email: "johndoe@example.com", 
            owner_first_name: "John", 
            owner_last_name: "Doe",
            image_url: "https://images.unsplash.com/photo-1572981779307-38b8cabb2407?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
            latitude: 30.2672,
            longitude: -97.7431
        ))
        .environmentObject(previewChatManager)
    }
}

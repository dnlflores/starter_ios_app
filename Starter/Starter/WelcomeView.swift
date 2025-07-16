import SwiftUI

struct WelcomeView: View {
    let username: String
    @State private var tools: [Tool] = []
    @State private var selectedView = 0
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header section with modern design
                VStack(spacing: 20) {
                    // Header spacing
                    Spacer()
                        .frame(height: 50)
                    
                    // Modern segmented control
                    VStack(spacing: 12) {
                        Text("Explore Available Tools")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 0) {
                            ForEach(0..<2) { index in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedView = index
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: index == 0 ? "list.bullet" : "map")
                                            .font(.system(size: 16, weight: .medium))
                                        Text(index == 0 ? "List" : "Map")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(selectedView == index ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedView == index ?
                                        Color.white.opacity(0.9) :
                                        Color.clear
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(4)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 30)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Content section
                if selectedView == 0 {
                    ZStack {
                        if isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.orange)
                                Text("Finding the perfect tools for you...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                        } else if tools.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "wrench.and.screwdriver")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.6))
                                Text("No tools available")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                Text("Check back later for new listings")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(tools) { tool in
                                        NavigationLink(destination: ToolDetailView(tool: tool)) {
                                            ToolCard(tool: tool)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 100) // Extra padding for tab bar
                            }
                            .background(Color(.systemBackground))
                        }
                    }
                } else {
                    MapView()
                        .navigationBarHidden(true)
                        .background(Color(.systemBackground))
                }
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .onAppear {
            loadTools()
        }
    }
    
    private func loadTools() {
        isLoading = true
        fetchTools { fetched in
            DispatchQueue.main.async {
                self.tools = fetched
                self.isLoading = false
            }
        }
    }
}

struct ToolCard: View {
    let tool: Tool
    
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
        VStack(alignment: .leading, spacing: 0) {
            // Image section
            ZStack {
                if let imageUrl = tool.image_url, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure(_):
                            // Image failed to load
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 30))
                                            .foregroundColor(.orange.opacity(0.7))
                                        Text("Failed to load")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                )
                        case .empty:
                            // Still loading
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .tint(.orange)
                                        Text("Loading...")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "wrench.and.screwdriver")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray.opacity(0.6))
                                Text("No Image")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                        )
                }
                
                // Price overlay
                VStack {
                    HStack {
                        Spacer()
                        Text("$\(formattedPrice)/day")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(12)
            }
            
            // Content section
            VStack(alignment: .leading, spacing: 12) {
                Text(tool.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let description = tool.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Owner info
                if let ownerName = tool.owner_username {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.7))
                        Text("by \(ownerName)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    WelcomeView(username: "John")
}

import SwiftUI

struct ListingsView: View {
    let username: String
    /// Controls presentation of the login sheet from the parent view.
    @Binding var showLogin: Bool
    /// Controls presentation of the signup sheet from the parent view.
    @Binding var showSignUp: Bool
    @AppStorage("authToken") private var authToken: String = ""
    @State private var user: User?
    @State private var tools: [Tool] = []
    @State private var isLoading = false
    
    // Check if we're in preview mode
    private var isInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    // Filter tools by current user (original logic)
    private var filteredTools: [Tool] {
        guard let user = user else { return [] }
        return tools.filter { $0.owner_id == user.id }
    }
    
    // Check if we should show empty state (only in normal app mode)
    private var shouldShowEmptyState: Bool {
        return !isInPreview && filteredTools.isEmpty && !isLoading
    }
    
    // Check if we should show dummy data (only in Preview mode)
    private var shouldShowDummyData: Bool {
        return isInPreview && filteredTools.isEmpty && !isLoading
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            if authToken.isEmpty {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.8))
                        Text("You are not logged in")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("Please log in to view your tools")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    VStack(spacing: 12) {
                        Button("Log In") {
                            showLogin = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .applyThemeBackground()
            } else {
                NavigationStack {
                    VStack(spacing: 0) {
                        // Modern header with gradient
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("My Tools")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Earn money by sharing your items")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                
                                Button(action: { loadData() }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .disabled(isLoading)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        
                        // Loading indicator
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.orange)
                                Text("Loading your tools...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                        } else {
                            // Main content
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    // Show empty state message when no tools in normal app mode
                                    if shouldShowEmptyState {
                                        EmptyStateView {
                                            loadData()
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 40)
                                    }
                                    // Show dummy data in Preview mode when no real tools
                                    else if shouldShowDummyData {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(dummyTools) { tool in
                                                ToolCardView(tool: tool)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                                    }
                                    // Show real tools
                                    else if !filteredTools.isEmpty {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(filteredTools) { tool in
                                                ToolCardView(tool: tool)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                            .background(Color(.systemGroupedBackground))
                        }
                    }
                    .navigationBarHidden(true)
                }
                .onAppear {
                    loadData()
                }
            }
        }
    }
    
    // Dummy tools for Preview mode only
    private var dummyTools: [Tool] {
        return [
            Tool(
                id: 1,
                name: "Power Drill",
                price: "15",
                description: "High-quality cordless drill with multiple bits. Perfect for home improvement projects.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores",
                image_url: nil
            ),
            Tool(
                id: 2,
                name: "Circular Saw",
                price: "25",
                description: "Heavy-duty 25-foot tape measure with standout up to 7 feet for one-person measuring. Features a durable nylon-coated steel blade with clear, easy-to-read markings in both imperial and metric units.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores",
                image_url: nil
            ),
            Tool(
                id: 3,
                name: "Hammer Set",
                price: "8",
                description: "Complete hammer set with different weights. Great for framing and general construction.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores",
                image_url: nil
            ),
            Tool(
                id: 4,
                name: "Angle Grinder",
                price: "20",
                description: "Heavy-duty angle grinder for metal cutting and polishing. Includes safety equipment.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores",
                image_url: nil
            ),
            Tool(
                id: 5,
                name: "Ladder (8ft)",
                price: "12",
                description: "Sturdy 8-foot aluminum ladder. Perfect for painting and light maintenance work.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores",
                image_url: nil
            ),
            Tool(
                id: 6,
                name: "Tile Saw",
                price: "30",
                description: "Professional tile saw for precise cuts. Includes diamond blade and water cooling system.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores",
                image_url: nil
            )
        ]
    }
    
    // Original data loading function with loading state
    private func loadData() {
        isLoading = true
        fetchUsers { users in
            if let match = users.first(where: { $0.username == username }) {
                DispatchQueue.main.async {
                    self.user = match
                }
                fetchTools { fetched in
                    DispatchQueue.main.async {
                        self.tools = fetched
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Tool Card View
struct ToolCardView: View {
    let tool: Tool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                        Text("No Image")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(tool.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(tool.description ?? "No description available")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("$\(tool.price)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Text("per day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Action for viewing tool details
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("No tools listed yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Start earning money by sharing your tools with the community")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            VStack(spacing: 12) {
                Button("Add Your First Tool") {
                    // Action to add tool
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 200)
                
                Button("Refresh") {
                    onRefresh()
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: 200)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
}

#Preview {
    ListingsView(username: "daniel", showLogin: .constant(false), showSignUp: .constant(false))
        .onAppear {
            UserDefaults.standard.set("daniel", forKey: "username")
        }
}


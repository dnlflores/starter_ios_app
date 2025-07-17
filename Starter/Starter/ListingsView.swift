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
    
    // Delete confirmation state
    @State private var showDeleteConfirmation = false
    @State private var toolToDelete: Tool?
    @State private var isDeleting = false
    
    // Edit coming soon alert state
    @State private var showEditComingSoon = false
    
    // Long press menu state
    @State private var showToolActionSheet = false
    @State private var selectedTool: Tool?
    
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
                // Modern logged-out view with better structure
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        // Icon
                        Image(systemName: "list.bullet.rectangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        Text("View Your Tools")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Keep track of all your tools that you own here.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            Button("Log In") {
                                showLogin = true
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            
                            Button("Sign Up") {
                                showSignUp = true
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.6))
                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
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
                                                ToolCardView(tool: tool) { action in
                                                    // No-op for dummy data in preview
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                                    }
                                    // Show real tools
                                    else if !filteredTools.isEmpty {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(filteredTools) { tool in
                                                ToolCardView(tool: tool) { action in
                                                    selectedTool = tool
                                                    switch action {
                                                    case .showMenu:
                                                        showToolActionSheet = true
                                                    case .edit:
                                                        showEditComingSoon = true
                                                    case .delete:
                                                        toolToDelete = tool
                                                        showDeleteConfirmation = true
                                                    }
                                                }
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
                .alert("Delete Tool", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let tool = toolToDelete {
                            performDeleteTool(tool)
                        }
                    }
                } message: {
                    if let tool = toolToDelete {
                        Text("Are you sure you want to delete '\(tool.name)'? This action cannot be undone.")
                    }
                }
                .alert("Edit Tool", isPresented: $showEditComingSoon) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Edit functionality is coming soon!")
                }
                .actionSheet(isPresented: $showToolActionSheet) {
                    ActionSheet(
                        title: Text(selectedTool?.name ?? "Tool Options"),
                        message: Text("Choose an action"),
                        buttons: [
                            .default(Text("Edit")) {
                                if let tool = selectedTool {
                                    showEditComingSoon = true
                                }
                            },
                            .destructive(Text("Delete")) {
                                if let tool = selectedTool {
                                    toolToDelete = tool
                                    showDeleteConfirmation = true
                                }
                            },
                            .cancel()
                        ]
                    )
                }
                .overlay(
                    // Deletion loading overlay
                    Group {
                        if isDeleting {
                            ZStack {
                                Color.black.opacity(0.3)
                                    .ignoresSafeArea()
                                
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .tint(.orange)
                                    Text("Deleting tool...")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.8))
                                )
                            }
                        }
                    }
                )
            }
        }
    }
    
    // Delete tool function
    private func performDeleteTool(_ tool: Tool) {
        isDeleting = true
        deleteTool(toolId: tool.id) { success in
            DispatchQueue.main.async {
                self.isDeleting = false
                if success {
                    // Remove the tool from the local array
                    self.tools.removeAll { $0.id == tool.id }
                } else {
                    // Show error message if needed
                    print("Failed to delete tool: \(tool.name)")
                }
                self.toolToDelete = nil
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
                image_url: "https://images.pexels.com/photos/3970342/pexels-photo-3970342.jpeg",
                latitude: 30.2672,
                longitude: -97.7431
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
                image_url: "https://images.pexels.com/photos/2351865/pexels-photo-2351865.jpeg",
                latitude: 30.2676,
                longitude: -97.7435
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
                image_url: "https://images.pexels.com/photos/5853935/pexels-photo-5853935.jpeg",
                latitude: 30.2680,
                longitude: -97.7439
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
                image_url: "https://images.pexels.com/photos/2027044/pexels-photo-2027044.jpeg",
                latitude: 30.2684,
                longitude: -97.7443
            ),
            Tool(
                id: 5,
                name: "Ladder (8ft)",
                price: "1200",
                description: "Sturdy 8-foot aluminum ladder. Perfect for painting and light maintenance work.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores",
                image_url: "https://images.pexels.com/photos/5803349/pexels-photo-5803349.jpeg",
                latitude: 30.2688,
                longitude: -97.7447
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
                image_url: "https://images.pexels.com/photos/17273711/pexels-photo-17273711.jpeg",
                latitude: 30.2692,
                longitude: -97.7451
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
enum ToolCardAction {
    case showMenu
    case edit
    case delete
}

struct ToolCardView: View {
    let tool: Tool
    let onAction: (ToolCardAction) -> Void
    
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
            // Image section with AsyncImage - Fixed to uniform size
            GeometryReader { geometry in
                ZStack {
                    if let imageUrl = tool.image_url, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: 120)
                                    .clipped()
                            case .failure(_):
                                // Image failed to load
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: geometry.size.width, height: 120)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.system(size: 20))
                                                .foregroundColor(.orange.opacity(0.7))
                                            Text("Failed to load")
                                                .font(.caption2)
                                                .foregroundColor(.gray.opacity(0.8))
                                        }
                                    )
                            case .empty:
                                // Still loading
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: geometry.size.width, height: 120)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.orange)
                                            Text("Loading...")
                                                .font(.caption2)
                                                .foregroundColor(.gray.opacity(0.8))
                                        }
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: geometry.size.width, height: 120)
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: geometry.size.width, height: 120)
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
                    }
                }
            }
            .frame(height: 120)
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
                        Text("$\(formattedPrice)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Text("per day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Removed the delete button and view details button
                    // Long press will now handle the menu
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
        .onTapGesture {
            // Tap to show action sheet
            onAction(.showMenu)
        }
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


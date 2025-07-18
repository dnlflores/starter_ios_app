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
    
    // Navigation state for editing tools
    @State private var navigationPath = NavigationPath()
    
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
                LoggedOutView(showLogin: $showLogin, showSignUp: $showSignUp)
            } else {
                LoggedInView(
                    navigationPath: $navigationPath,
                    isLoading: isLoading,
                    shouldShowEmptyState: shouldShowEmptyState,
                    shouldShowDummyData: shouldShowDummyData,
                    filteredTools: filteredTools,
                    dummyTools: dummyTools,
                    columns: columns,
                    showToolActionSheet: $showToolActionSheet,
                    selectedTool: $selectedTool,
                    toolToDelete: $toolToDelete,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    isDeleting: isDeleting,
                    onRefresh: { loadData() },
                    onToolAction: { action, tool in
                        selectedTool = tool
                        switch action {
                        case .showMenu:
                            showToolActionSheet = true
                        case .edit:
                            navigationPath.append(tool)
                        case .delete:
                            toolToDelete = tool
                            showDeleteConfirmation = true
                        }
                    },
                    onDeleteConfirmed: {
                        if let tool = toolToDelete {
                            performDeleteTool(tool)
                        }
                    },
                    onEditFromSheet: {
                        if let tool = selectedTool {
                            navigationPath.append(tool)
                        }
                    },
                    onDeleteFromSheet: {
                        if let tool = selectedTool {
                            toolToDelete = tool
                            showDeleteConfirmation = true
                        }
                    }
                )
            }
        }
        .onAppear {
            loadData()
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

// MARK: - Logged Out View
struct LoggedOutView: View {
    @Binding var showLogin: Bool
    @Binding var showSignUp: Bool
    
    var body: some View {
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
    }
}

// MARK: - Logged In View
struct LoggedInView: View {
    @Binding var navigationPath: NavigationPath
    let isLoading: Bool
    let shouldShowEmptyState: Bool
    let shouldShowDummyData: Bool
    let filteredTools: [Tool]
    let dummyTools: [Tool]
    let columns: [GridItem]
    @Binding var showToolActionSheet: Bool
    @Binding var selectedTool: Tool?
    @Binding var toolToDelete: Tool?
    @Binding var showDeleteConfirmation: Bool
    let isDeleting: Bool
    let onRefresh: () -> Void
    let onToolAction: (ToolCardAction, Tool) -> Void
    let onDeleteConfirmed: () -> Void
    let onEditFromSheet: () -> Void
    let onDeleteFromSheet: () -> Void
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                HeaderView(onRefresh: onRefresh, isLoading: isLoading)
                
                if isLoading {
                    LoadingView()
                } else {
                    MainContentView(
                        shouldShowEmptyState: shouldShowEmptyState,
                        shouldShowDummyData: shouldShowDummyData,
                        filteredTools: filteredTools,
                        dummyTools: dummyTools,
                        columns: columns,
                        onRefresh: onRefresh,
                        onToolAction: onToolAction
                    )
                }
            }
            .navigationDestination(for: Tool.self) { tool in
                EditToolView(
                    tool: tool,
                    isPresented: .constant(true),
                    onToolUpdated: {
                        onRefresh() // Refresh the tools list
                        navigationPath.removeLast() // Go back after update
                    },
                    navigationPath: $navigationPath
                )
                .navigationBarHidden(true)
            }
            .navigationBarHidden(true)
        }
        .overlay(
            Group {
                if isDeleting {
                    DeletingOverlayView()
                }
                
                // Custom Tool Action Modal
                if showToolActionSheet {
                    ToolActionModal(
                        tool: selectedTool,
                        isPresented: $showToolActionSheet,
                        onEdit: onEditFromSheet,
                        onDelete: onDeleteFromSheet
                    )
                }
                
                // Custom Delete Confirmation Modal
                if showDeleteConfirmation {
                    DeleteConfirmationModal(
                        tool: toolToDelete,
                        isPresented: $showDeleteConfirmation,
                        onConfirm: onDeleteConfirmed
                    )
                }
            }
        )
    }
}

// MARK: - Header View
struct HeaderView: View {
    let onRefresh: () -> Void
    let isLoading: Bool
    
    var body: some View {
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
                
                Button(action: { onRefresh() }) {
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
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
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
    }
}

// MARK: - Main Content View
struct MainContentView: View {
    let shouldShowEmptyState: Bool
    let shouldShowDummyData: Bool
    let filteredTools: [Tool]
    let dummyTools: [Tool]
    let columns: [GridItem]
    let onRefresh: () -> Void
    let onToolAction: (ToolCardAction, Tool) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if shouldShowEmptyState {
                    EmptyStateView(onRefresh: onRefresh)
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                } else if shouldShowDummyData {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(dummyTools) { tool in
                            ToolCardView(tool: tool) { action in
                                // No-op for dummy data in preview
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                } else if !filteredTools.isEmpty {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredTools) { tool in
                            ToolCardView(tool: tool) { action in
                                onToolAction(action, tool)
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

// MARK: - Deleting Overlay View
struct DeletingOverlayView: View {
    var body: some View {
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

// MARK: - Tool Action Modal
struct ToolActionModal: View {
    let tool: Tool?
    @Binding var isPresented: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            Button {
                                isPresented = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        VStack(spacing: 8) {
                            Text(tool?.name ?? "Tool Options")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Choose what you'd like to do")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Action buttons
                    VStack(spacing: 0) {
                        Button {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onEdit()
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Edit Tool")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("Update details and pricing")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color.clear)
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        Button {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onDelete()
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Delete Tool")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("Remove from your listings")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color.clear)
                    }
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Cancel button
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .background(Color.clear)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
                .padding(.horizontal, 16)
                .padding(.bottom, 34) // Account for safe area
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// MARK: - Delete Confirmation Modal
struct DeleteConfirmationModal: View {
    let tool: Tool?
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            DeleteConfirmationContent(
                tool: tool,
                isPresented: $isPresented,
                onConfirm: onConfirm
            )
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - Delete Confirmation Content
struct DeleteConfirmationContent: View {
    let tool: Tool?
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            DeleteConfirmationIcon()
            
            DeleteConfirmationText(toolName: tool?.name)
            
            DeleteConfirmationButtons(
                isPresented: $isPresented,
                onConfirm: onConfirm
            )
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 10)
        .padding(.horizontal, 32)
    }
}

// MARK: - Delete Confirmation Icon
struct DeleteConfirmationIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 80, height: 80)
            
            Image(systemName: "trash.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.orange)
        }
        .padding(.top, 24)
    }
}

// MARK: - Delete Confirmation Text
struct DeleteConfirmationText: View {
    let toolName: String?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Delete Tool")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                if let toolName = toolName {
                    (Text("Are you sure you want to delete")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    + Text(" '\(toolName)'")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    + Text("?")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary))
                        .multilineTextAlignment(.center)
                }
                
                Text("This action cannot be undone and will remove the tool from your listings permanently.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

// MARK: - Delete Confirmation Buttons
struct DeleteConfirmationButtons: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button {
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onConfirm()
                }
            } label: {
                Text("Delete Tool")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button {
                isPresented = false
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

#Preview {
    ListingsView(username: "daniel", showLogin: .constant(false), showSignUp: .constant(false))
        .onAppear {
            UserDefaults.standard.set("daniel", forKey: "username")
        }
}


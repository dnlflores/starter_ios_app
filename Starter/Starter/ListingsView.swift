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

    var body: some View {
        ZStack {
            if authToken.isEmpty {
                VStack(spacing: 16) {
                    Text("You are not logged in.")
                        .font(.title2)
                    Button("Log In") {
                        showLogin = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    Button("Sign Up") {
                        showSignUp = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                }
                .padding()
            } else {
                NavigationStack {
                    VStack(spacing: 0) {
                        // Custom extended navigation header
                        VStack {
                            HStack {
                                Text("My Tools")
                                    .font(.largeTitle)
                                    .foregroundColor(.purple)
                                    .bold()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .background(Color.black)
                        
                        ZStack {
                            // Show empty state message when no tools in normal app mode
                            if shouldShowEmptyState {
                                VStack(spacing: 16) {
                                    Image(systemName: "wrench.and.screwdriver")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    Text("No tools listed yet")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                    Text("Post your first tool to start earning money by sharing your items with the community.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    Button("Refresh") {
                                        loadData()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.purple)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            // Show dummy data in Preview mode when no real tools
                            else if shouldShowDummyData {
                                List(dummyTools) { tool in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tool.name)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        Text(truncateText(tool.description ?? "No description available", maxLength: 80))
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        HStack {
                                            Text("\(tool.price)/day")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                                .bold()
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(Color.black.opacity(0.3))
                                                .cornerRadius(5)
                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .listRowBackground(Color.clear)
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .ignoresSafeArea()
                                .padding(.bottom, 0.5)
                            }
                            // Show real tools
                            else {
                                List(filteredTools) { tool in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tool.name)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        Text(truncateText(tool.description ?? "No description available", maxLength: 80))
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        HStack {
                                            Text("\(tool.price)/day")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                                .bold()
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(Color.black.opacity(0.3))
                                                .cornerRadius(5)
                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .listRowBackground(Color.clear)
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .ignoresSafeArea()
                                .padding(.bottom, 0.5)
                            }
                            
                            // Loading indicator
                            if isLoading {
                                ProgressView("Loading your tools...")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.black.opacity(0.3))
                            }
                        }
                        .applyThemeBackground()
                    }
                    .navigationBarHidden(true)
                }
                .onAppear {
                    loadData()
                }
            }
        }
    }
    
    // Helper function to truncate text to specified length
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        } else {
            return String(text.prefix(maxLength)) + "..."
        }
    }
    
    // Dummy tools for Preview mode only
    private var dummyTools: [Tool] {
        return [
            Tool(
                id: 1,
                name: "Power Drill",
                price: "$15",
                description: "High-quality cordless drill with multiple bits. Perfect for home improvement projects.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores"
            ),
            Tool(
                id: 2,
                name: "Circular Saw",
                price: "$25",
                description: "Professional-grade circular saw for wood cutting. Includes safety guide and extra blades.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores"
            ),
            Tool(
                id: 3,
                name: "Hammer Set",
                price: "$8",
                description: "Complete hammer set with different weights. Great for framing and general construction.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores"
            ),
            Tool(
                id: 4,
                name: "Angle Grinder",
                price: "$20",
                description: "Heavy-duty angle grinder for metal cutting and polishing. Includes safety equipment.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores"
            ),
            Tool(
                id: 5,
                name: "Ladder (8ft)",
                price: "$12",
                description: "Sturdy 8-foot aluminum ladder. Perfect for painting and light maintenance work.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores"
            ),
            Tool(
                id: 6,
                name: "Tile Saw",
                price: "$30",
                description: "Professional tile saw for precise cuts. Includes diamond blade and water cooling system.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores"
            ),
            Tool(
                id: 7,
                name: "Tile Saw 2",
                price: "$30",
                description: "Professional tile saw for precise cuts. Includes diamond blade and water cooling system.",
                owner_id: 1,
                owner_username: "daniel",
                owner_email: "daniel@example.com",
                owner_first_name: "Daniel",
                owner_last_name: "Flores"
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

#Preview {
    ListingsView(username: "daniel", showLogin: .constant(false), showSignUp: .constant(false))
        .onAppear {
            UserDefaults.standard.set("daniel", forKey: "username")
        }
}


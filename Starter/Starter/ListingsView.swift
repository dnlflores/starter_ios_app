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
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.6),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        List(filteredTools) { tool in
                            NavigationLink(destination: ToolDetailView(tool: tool)) {
                                VStack(alignment: .leading) {
                                    Text(tool.name)
                                        .font(.headline)
                                    Text(tool.description ?? "No description available")
                                        .font(.subheadline)
                                }
                            }
                            .listRowBackground(
                                Color.clear
                            )
                        }
                        .listStyle(.plain)
                        // This is the magic iOS 16+ call: hide the List’s sheet.
                        .scrollContentBackground(.hidden)
                        // And ensure whatever remains of the List’s “container” is clear:
                        .background(Color.clear)
                    }
                    .navigationTitle("RNTL")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .onAppear {
                    loadData()
                }
            }
        }
    }

    private var filteredTools: [Tool] {
        guard let user = user else { return [] }
        return tools.filter { $0.owner_id == user.id }
    }

    private func loadData() {
        fetchUsers { users in
            if let match = users.first(where: { $0.username == username }) {
                DispatchQueue.main.async {
                    self.user = match
                }
                fetchTools { fetched in
                    DispatchQueue.main.async {
                        self.tools = fetched
                    }
                }
            }
        }
    }
}

#Preview {
    ListingsView(username: "daniel", showLogin: .constant(false), showSignUp: .constant(false))
}

import SwiftUI

struct ListingsView: View {
    let username: String
    @State private var user: User?
    @State private var tools: [Tool] = []

    var body: some View {
        NavigationStack {
            List(filteredTools) { tool in
                NavigationLink(destination: ToolDetailView(tool: tool)) {
                    VStack(alignment: .leading) {
                        Text(tool.name)
                            .font(.headline)
                        Text(tool.description ?? "No description available")
                            .font(.subheadline)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("RNTL")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadData()
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
    ListingsView(username: "User")
}

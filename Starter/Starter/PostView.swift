import SwiftUI

struct PostView: View {
    /// Controls presentation of the login sheet from the parent view.
    @Binding var showLogin: Bool
    /// Binding to the selected tab from `MainTabView` so the view can switch
    /// tabs when canceling or after saving a post.
    @Binding var selection: Int
    /// Stores the previously selected tab so we can return to it.
    @Binding var previousSelection: Int

    @AppStorage("authToken") private var authToken: String = ""
    @AppStorage("username") private var username: String = "Guest"

    @State private var name = ""
    @State private var price = ""
    @State private var description = ""

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
                    .tint(.green)
                }
                .padding()
            } else {
                NavigationStack {
                    Form {
                        Section (header: Text("Tool Information")) {
                            TextField("Name", text: $name)
                            TextField("Price", text: $price)
                                .keyboardType(.decimalPad)
                            TextField("Description", text: $description, axis: .vertical)
                        }
                        Section {
                            HStack() {
                                Spacer()
                                Button("Save") {
                                    savePost()
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Cancel") {
                                    selection = previousSelection
                                }
                                .buttonStyle(.bordered)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .accentColor(.purple)
                    .navigationTitle("New Listing")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
    }

    /// Save the entered data to the server and return to the previous tab on success.
    private func savePost() {
        fetchUsers { users in
            guard let match = users.first(where: { $0.username == username }) else {
                return
            }
            let ownerId = match.id
            let createdAt = ISO8601DateFormatter().string(from: Date())
            createTool(name: name, price: price, description: description, ownerId: ownerId, createdAt: createdAt, authToken: authToken) { success in
                if success {
                    DispatchQueue.main.async {
                        name = ""
                        price = ""
                        description = ""
                        selection = previousSelection
                    }
                }
            }
        }
    }
}

#Preview {
    PostView(showLogin: .constant(false), selection: .constant(2), previousSelection: .constant(0))
}

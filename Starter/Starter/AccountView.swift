import SwiftUI

struct AccountView: View {
    let username: String
    @State private var user: User?

    var body: some View {
        VStack(spacing: 20) {
            Text("Account Details")
                .font(.largeTitle)

            if let user = user {
                Text("Username: \(user.username)")
                    .font(.title2)
                Text("User ID: \(user.id)")
                    .font(.title3)
            } else {
                Text("Username: \(username)")
                    .font(.title2)
                Text("Loading user info...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            fetchUsers { users in
                if let match = users.first(where: { $0.username == username }) {
                    DispatchQueue.main.async {
                        self.user = match
                    }
                }
            }
        }
    }
}

#Preview {
    AccountView(username: "User")
}

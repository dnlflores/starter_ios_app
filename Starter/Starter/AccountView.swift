import SwiftUI

struct AccountView: View {
    let username: String
    @Binding var showLogin: Bool
    @AppStorage("authToken") private var authToken: String = ""
    @State private var user: User?

    var body: some View {
        if authToken.isEmpty {
            VStack(spacing: 16) {
                Text("You are not logged in.")
                    .font(.title2)
                Button("Log In") {
                    showLogin = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account Details")
                        .font(.largeTitle)
                        .padding(.bottom, 8)

                    if let user = user {
                        Group {
                            Text("Username: \(user.username)")
                                .font(.title2)
                            Text("User ID: \(user.id)")
                                .font(.title3)
                            if let firstName = user.first_name {
                                Text("First Name: \(firstName)")
                            }
                        if let lastName = user.last_name {
                            Text("Last Name: \(lastName)")
                        }
                        if let email = user.email {
                            Text("Email: \(email)")
                        }
                        if let phone = user.phone {
                            Text("Phone: \(phone)")
                        }
                        if let address = user.address {
                            Text("Address: \(address)")
                        }
                        if let city = user.city {
                            Text("City: \(city)")
                        }
                        if let state = user.state {
                            Text("State: \(state)")
                        }
                        if let zip = user.zip {
                            Text("ZIP: \(zip)")
                        }
                        if let isSeller = user.is_seller {
                            Text("Seller: \(isSeller ? "Yes" : "No")")
                        }
                        if let isAdmin = user.is_admin {
                            Text("Admin: \(isAdmin ? "Yes" : "No")")
                        }
                        if let created = user.created_at {
                            Text("Created: \(created)")
                        }
                        if let updated = user.updated_at {
                            Text("Updated: \(updated)")
                        }
                        }
                    } else {
                        Text("Username: \(username)")
                            .font(.title2)
                        Text("Loading user info...")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                Button("Log Out") {
                    logout()
                    authToken = ""
                    showLogin = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
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
}

#Preview {
    AccountView(username: "daniel", showLogin: .constant(false))
}

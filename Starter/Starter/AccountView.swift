import SwiftUI

struct AccountView: View {
    let username: String
    @Binding var showLogin: Bool
    @Binding var showSignUp: Bool
    @AppStorage("authToken") private var authToken: String = ""
    @State private var user: User?

    var body: some View {
        ZStack {
            if authToken.isEmpty {
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        // Icon
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        Text("Welcome to Your Account")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Sign in to access your profile, manage your listings, and connect with other users.")
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
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 20) {
                            // Profile Picture
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    )
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 40)
                            
                            // Username
                            Text(user?.username ?? username)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            // User Status Badge
                            HStack(spacing: 8) {
                                if let isSeller = user?.is_seller, isSeller {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                        Text("Seller")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.9))
                                    )
                                }
                                
                                if let isAdmin = user?.is_admin, isAdmin {
                                    HStack(spacing: 4) {
                                        Image(systemName: "shield.fill")
                                            .font(.caption)
                                        Text("Admin")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.9))
                                    )
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 24)
                        
                        // Content Cards
                        VStack(spacing: 16) {
                            // Personal Information Card
                            if let user = user {
                                AccountInfoCard(title: "Personal Information", icon: "person.circle") {
                                    VStack(spacing: 12) {
                                        if let firstName = user.first_name, let lastName = user.last_name {
                                            AccountInfoRow(label: "Name", value: "\(firstName) \(lastName)")
                                        }
                                        
                                        if let email = user.email {
                                            AccountInfoRow(label: "Email", value: email)
                                        }
                                        
                                        if let phone = user.phone {
                                            AccountInfoRow(label: "Phone", value: phone)
                                        }
                                        
                                        AccountInfoRow(label: "User ID", value: "\(user.id)")
                                    }
                                }
                                
                                // Address Information Card
                                if user.address != nil || user.city != nil || user.state != nil || user.zip != nil {
                                    AccountInfoCard(title: "Address", icon: "location.circle") {
                                        VStack(spacing: 12) {
                                            if let address = user.address {
                                                AccountInfoRow(label: "Street", value: address)
                                            }
                                            
                                            if let city = user.city {
                                                AccountInfoRow(label: "City", value: city)
                                            }
                                            
                                            if let state = user.state {
                                                AccountInfoRow(label: "State", value: state)
                                            }
                                            
                                            if let zip = user.zip {
                                                AccountInfoRow(label: "ZIP Code", value: zip)
                                            }
                                        }
                                    }
                                }
                                
                                // Account Information Card
                                AccountInfoCard(title: "Account Details", icon: "info.circle") {
                                    VStack(spacing: 12) {
                                        if let created = user.created_at {
                                            AccountInfoRow(label: "Member Since", value: formatDate(created))
                                        }
                                        
                                        if let updated = user.updated_at {
                                            AccountInfoRow(label: "Last Updated", value: formatDate(updated))
                                        }
                                        
                                        AccountInfoRow(label: "Account Type", value: user.is_seller == true ? "Seller" : "Member")
                                    }
                                }
                            } else {
                                // Loading state
                                AccountInfoCard(title: "Loading Profile", icon: "person.circle") {
                                    VStack(spacing: 12) {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.orange)
                                            
                                            Text("Loading your profile information...")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            
                            // Logout Button
                            Button(action: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    authToken = ""
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                        .font(.system(size: 18, weight: .medium))
                                    
                                    Text("Log Out")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 100) // Extra padding for tab bar
                    }
                }
                .applyThemeBackground()
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
    
    // Helper function to format dates
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Supporting Views

struct AccountInfoCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.orange)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
    }
}

struct AccountInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray.opacity(0.6))
                .textCase(.uppercase)
            
            Text(value)
                .font(.body)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 4)
    }
}

#Preview {
    AccountView(username: "daniel", showLogin: .constant(false), showSignUp: .constant(false))
}

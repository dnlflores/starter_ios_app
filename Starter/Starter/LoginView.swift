import SwiftUI

/// Modal view that handles user login.
struct LoginView: View {
    /// Controls presentation from the parent view.
    @Binding var showLogin: Bool
    /// Controls presentation of the signup sheet from the parent view.
    @Binding var showSignUp: Bool
    @AppStorage("username") private var storedUsername: String = "Guest"
    @AppStorage("authToken") private var authToken: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false

    var body: some View {
        ZStack {
            // App's signature gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.red, Color.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main login card with Airbnb-style design
                VStack(spacing: 28) {
                    // Header section
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                        
                        Text("Welcome Back")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue your journey")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Form section
                    VStack(spacing: 20) {
                        // Username field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("Enter your username", text: $username)
                                .autocorrectionDisabled()
                                .textFieldStyle(.plain)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.9))
                                )
                                .foregroundColor(.black)
                                .dismissKeyboardOnSwipeDown()
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.9))
                                )
                                .foregroundColor(.black)
                                .dismissKeyboardOnSwipeDown()
                        }
                    }
                    
                    // Buttons section
                    VStack(spacing: 16) {
                        Button(action: {
                            login(username: username, password: password) { success in
                                DispatchQueue.main.async {
                                    if success {
                                        storedUsername = username
                                        showLogin = false
                                    } else {
                                        showingAlert = true
                                    }
                                }
                            }
                        }) {
                            Text("Log In")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                        
                        Button("Don't have an account? Sign Up") {
                            showSignUp = true
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.25))
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .alert("Login Failed", isPresented: $showingAlert) {
            Button("Try Again", role: .cancel) {}
        } message: {
            Text("Please check your username and password and try again.")
        }
    }
}

#Preview {
    LoginView(showLogin: .constant(true), showSignUp: .constant(false))
}

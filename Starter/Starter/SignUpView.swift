import SwiftUI

/// Modal view that handles user signup.
struct SignUpView: View {
    /// Controls presentation from the parent view.
    @Binding var showSignUp: Bool
    /// Binding back to the login sheet so it can be dismissed on success.
    @Binding var showLogin: Bool
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var phone: String = ""
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
            
            ScrollView {
                VStack(spacing: 0) {
                    // Top spacing
                    Spacer()
                        .frame(height: 60)
                    
                    // Main signup card with Airbnb-style design
                    VStack(spacing: 32) {
                        // Header section
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            
                            Text("Join Our Community")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Start sharing and borrowing tools with your neighbors")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // Account Information Section
                        VStack(spacing: 24) {
                            SignupSectionHeader(title: "Account Information", icon: "person.circle")
                            
                            VStack(spacing: 16) {
                                SignupTextField(label: "Username", text: $username, placeholder: "Choose a username")
                                SignupTextField(label: "Email", text: $email, placeholder: "Enter your email address")
                                SignupSecureField(label: "Password", text: $password, placeholder: "Create a secure password")
                            }
                        }
                        
                        // Address Information Section
                        VStack(spacing: 24) {
                            SignupSectionHeader(title: "Address Information", icon: "house.circle")
                            
                            VStack(spacing: 16) {
                                SignupTextField(label: "Street Address", text: $street, placeholder: "123 Main St")
                                
                                HStack(spacing: 12) {
                                    SignupTextField(label: "City", text: $city, placeholder: "City")
                                    SignupTextField(label: "State", text: $state, placeholder: "State")
                                        .frame(maxWidth: 100)
                                }
                                
                                HStack(spacing: 12) {
                                    SignupTextField(label: "ZIP Code", text: $zip, placeholder: "12345")
                                        .frame(maxWidth: 120)
                                    SignupTextField(label: "Phone", text: $phone, placeholder: "(555) 123-4567")
                                }
                            }
                        }
                        
                        // Buttons section
                        VStack(spacing: 16) {
                            Button("Create Account") {
                                signup(username: username, email: email, password: password, street: street, city: city, state: state, zip: zip, phone: phone) { success in
                                    DispatchQueue.main.async {
                                        if success {
                                            login(username: username, password: password) { loggedIn in
                                                DispatchQueue.main.async {
                                                    if loggedIn {
                                                        showSignUp = false
                                                        showLogin = false
                                                    } else {
                                                        showingAlert = true
                                                    }
                                                }
                                            }
                                        } else {
                                            showingAlert = true
                                        }
                                    }
                                }
                            }
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
                            
                            Button("Already have an account? Log In") {
                                showSignUp = false
                                showLogin = true
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
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: 60)
                }
            }
        }
        .alert("Signup Failed", isPresented: $showingAlert) {
            Button("Try Again", role: .cancel) {}
        } message: {
            Text("Please check your information and try again.")
        }
    }
}

// MARK: - Signup Components

struct SignupSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct SignupTextField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            TextField(placeholder, text: $text)
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
    }
}

struct SignupSecureField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            SecureField(placeholder, text: $text)
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
}

#Preview {
    SignUpView(showSignUp: .constant(true), showLogin: .constant(false))
}

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
            LinearGradient(
                gradient: Gradient(colors: [Color.red, Color.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 24) {
                    Text("Log In")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    VStack(spacing: 16) {
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocapitalization(.none)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .dismissKeyboardOnSwipeDown()

                        SecureField("Password", text: $password)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .dismissKeyboardOnSwipeDown()

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
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
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
        }
        .alert("Login failed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

#Preview {
    LoginView(showLogin: .constant(true), showSignUp: .constant(false))
}

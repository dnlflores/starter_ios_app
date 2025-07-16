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
            LinearGradient(
                gradient: Gradient(colors: [Color.red, Color.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 0)

                    VStack(spacing: 24) {
                        Text("Sign Up")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Group {
                            TextField("Username", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocapitalization(.none)
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocapitalization(.none)
                            SecureField("Password", text: $password)
                            TextField("Street", text: $street)
                            TextField("City", text: $city)
                            TextField("State", text: $state)
                            TextField("ZIP", text: $zip)
                            TextField("Phone", text: $phone)
                        }
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

                        Button("Create Account") {
                            signup(
                                username: username,
                                email: email,
                                password: password,
                                street: street,
                                city: city,
                                state: state,
                                zip: zip,
                                phone: phone
                            ) { success in
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
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.6))
                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 24)

                    Spacer(minLength: 0)
                }
            }
        }
        .alert("Signup failed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

#Preview {
    SignUpView(showSignUp: .constant(true), showLogin: .constant(false))
}

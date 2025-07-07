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
                gradient: Gradient(colors: [Color.black.opacity(0.6), Color.blue.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer()
                Text("Sign Up")
                    .font(.largeTitle)
                    .bold()
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
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
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
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.8))
                .foregroundColor(.blue)
                .cornerRadius(8)
                .padding(.horizontal)
                Spacer()
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

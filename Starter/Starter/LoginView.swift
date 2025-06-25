import SwiftUI

/// Modal view that handles user login.
struct LoginView: View {
    /// Controls presentation from the parent view.
    @Binding var showLogin: Bool
    @AppStorage("username") private var storedUsername: String = "Guest"
    @AppStorage("authToken") private var authToken: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.6), Color.blue.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                Text("Log In")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
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
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .tint(.blue)
                Spacer()
            }
        }
        .alert("Login failed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

#Preview {
    LoginView(showLogin: .constant(true))
}

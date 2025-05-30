import SwiftUI

struct ContentView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var loggedIn = false

    var body: some View {
        if loggedIn {
            WelcomeView(username: username)
        } else {
            loginForm
        }
    }

    private var loginForm: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                Text("Log In")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Button(action: {
                    login(username: username, password: password) { success in
                        DispatchQueue.main.async {
                            if success {
                                loggedIn = true
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
                Spacer()
            }
        }
        .alert("Login failed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

#Preview {
    ContentView()
}

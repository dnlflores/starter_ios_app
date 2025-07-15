import SwiftUI
import MapKit

struct PostView: View {
    /// Controls presentation of the login sheet from the parent view.
    @Binding var showLogin: Bool
    /// Controls presentation of the signup sheet from the parent view.
    @Binding var showSignUp: Bool
    /// Binding to the selected tab from `MainTabView` so the view can switch
    /// tabs when canceling or after saving a post.
    @Binding var selection: Int
    /// Stores the previously selected tab so we can return to it.
    @Binding var previousSelection: Int
    
    @AppStorage("authToken") private var authToken: String = ""
    @AppStorage("username") private var username: String = "Guest"
    
    @State private var name = ""
    @State private var price: Double = 0.0
    @State private var description = ""
    
    @StateObject private var addressService = AddressSearchService()
    @State private var address = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    
    // Animation states
    @State private var isFormVisible = false
    @State private var showSaveSuccess = false
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US") // U.S. Dollar
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    var body: some View {
        ZStack {
            if authToken.isEmpty {
                // Login prompt card
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        // Icon
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        Text("Share Your Tools")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Sign in to start listing your tools and earn money from your unused equipment.")
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
            } else {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header
                            VStack(spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Create New Listing")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("Share your tools with the community")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                .padding(.bottom, 24)
                            }
                            
                            // Form Card
                            VStack(spacing: 24) {
                                // Basic Information Section
                                FormSection(title: "Basic Information", icon: "info.circle.fill") {
                                    VStack(spacing: 16) {
                                        CustomTextField(
                                            title: "Tool Name",
                                            text: $name,
                                            placeholder: "e.g., Power Drill, Ladder, Lawn Mower"
                                        )
                                        
                                        CustomTextEditor(
                                            title: "Description",
                                            text: $description,
                                            placeholder: "Describe your tool's condition, features, and any special instructions..."
                                        )
                                    }
                                }
                                
                                // Location Section
                                FormSection(title: "Location", icon: "location.fill") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Address")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        AddressSearchField(
                                            service: addressService,
                                            selectedAddress: $address,
                                            selectedCoordinate: $selectedCoordinate
                                        )
                                    }
                                }
                                
                                // Pricing Section
                                FormSection(title: "Pricing", icon: "dollarsign.circle.fill") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Daily Rental Price")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        TextField("$0.00", value: $price, formatter: currencyFormatter)
                                            .keyboardType(.decimalPad)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.black.opacity(0.3))
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                            .dismissKeyboardOnSwipeDown()
                                    }
                                }
                                
                                // Save Button
                                Button(action: {
                                    savePost()
                                }) {
                                    HStack {
                                        if showSaveSuccess {
                                            Image(systemName: "checkmark")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                        } else {
                                            Text("Publish Listing")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                    )
                                }
                                .disabled(name.isEmpty || description.isEmpty || price <= 0)
                                .opacity(name.isEmpty || description.isEmpty || price <= 0 ? 0.6 : 1)
                                .scaleEffect(showSaveSuccess ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: showSaveSuccess)
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .applyThemeBackground()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancel") {
                                selection = previousSelection
                            }
                            .foregroundStyle(Color.white)
                            .fontWeight(.medium)
                        }
                    }
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.6)) {
                            isFormVisible = true
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
    }
    
    /// Save the entered data to the server and return to the previous tab on success.
    private func savePost() {
        // Show loading state
        withAnimation(.easeInOut(duration: 0.2)) {
            showSaveSuccess = false
        }
        
        fetchUsers { users in
            guard let match = users.first(where: { $0.username == username }) else {
                return
            }
            let ownerId = match.id
            let createdAt = ISO8601DateFormatter().string(from: Date())
            createTool(name: name, price: price, description: description, ownerId: ownerId, createdAt: createdAt, authToken: authToken) { success in
                if success {
                    DispatchQueue.main.async {
                        // Show success animation
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSaveSuccess = true
                        }
                        
                        // Reset form and navigate back after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            name = ""
                            price = 0.0
                            description = ""
                            address = ""
                            selectedCoordinate = nil
                            selection = previousSelection
                            showSaveSuccess = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Custom Components

struct FormSection<Content: View>: View {
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .dismissKeyboardOnSwipeDown()
        }
    }
}

struct CustomTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.body)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .dismissKeyboardOnSwipeDown()
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.2))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PostView(showLogin: .constant(false), showSignUp: .constant(false), selection: .constant(2), previousSelection: .constant(0))
}

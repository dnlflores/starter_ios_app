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
    
    // Image picker states
    @State private var selectedImage: UIImage?
    @State private var isImagePickerShowing = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingImageSourceSelection = false
    
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
                ZStack(alignment: .top) {
                    // Header - positioned at the very top
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Create New Listing")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Share your tools with the community")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            // Cancel button
                            Button(action: {
                                cancelPost()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.black.opacity(0.2))
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 70) // Account for status bar
                        .padding(.bottom, 24)
                        .background(Color.red)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 500, height: 0.5),
                            alignment: .bottom
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(.all, edges: .top)
                    .zIndex(1)
                    
                    // Content ScrollView - starts below header
                    ScrollView {
                        VStack(spacing: 0) {
                            // Spacer to push content below header
                            Spacer()
                                .frame(height: 100) // Adjust this to match header height
                            
                            // Form Card
                            VStack(spacing: 24) {
                                // Basic Information Section
                                FormSection(title: "Basic Information", icon: "info.circle.fill") {
                                    VStack(spacing: 16) {
                                        CustomTextField(
                                            title: "Tool Name",
                                            text: $name,
                                            placeholder: "Power Drill, Ladder, Lawn Mower"
                                        )
                                        
                                        CustomTextEditor(
                                            title: "Description",
                                            text: $description,
                                            placeholder: "Describe your tool's condition, features, and any special instructions..."
                                        )
                                        
                                        // Image picker section
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Photo")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                            
                                            // Image preview
                                            if let selectedImage = selectedImage {
                                                Image(uiImage: selectedImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(maxHeight: 200)
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                            
                                            // Image picker button
                                            Button(action: {
                                                showingImageSourceSelection = true
                                            }) {
                                                HStack {
                                                    Image(systemName: selectedImage == nil ? "photo.badge.plus" : "photo.badge.arrow.down")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.white)
                                                    
                                                    Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.white)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                )
                                            }
                                        }
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
                                                    startPoint: .trailing,
                                                    endPoint: .leading
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
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.6)) {
                            isFormVisible = true
                        }
                    }
                } // Close ZStack
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyThemeBackground()
        .confirmationDialog("Select Image Source", isPresented: $showingImageSourceSelection) {
            Button("Camera") {
                if ImagePicker.isCameraAvailable {
                    imagePickerSourceType = .camera
                    isImagePickerShowing = true
                }
            }
            Button("Photo Library") {
                imagePickerSourceType = .photoLibrary
                isImagePickerShowing = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $isImagePickerShowing) {
            ImagePicker(selectedImage: $selectedImage, isPickerShowing: $isImagePickerShowing, sourceType: imagePickerSourceType)
        }
    }
    
    /// Save the entered data to the server and return to the previous tab on success.
    private func savePost() {
        // Show loading state
        withAnimation(.easeInOut(duration: 0.2)) {
            showSaveSuccess = false
        }
        
        // Convert address to coordinates if we don't have them yet
        if !address.isEmpty && selectedCoordinate == nil {
            print("🔍 Converting address to coordinates: \(address)")
            convertAddressToCoordinates(address: address) { coordinate in
                DispatchQueue.main.async {
                    if let coordinate = coordinate {
                        self.selectedCoordinate = coordinate
                        print("✅ Address converted successfully!")
                        print("📍 Latitude: \(coordinate.latitude)")
                        print("📍 Longitude: \(coordinate.longitude)")
                        self.proceedWithSave()
                    } else {
                        print("❌ Failed to convert address to coordinates")
                        // Proceed without coordinates
                        self.proceedWithSave()
                    }
                }
            }
        } else {
            // Log existing coordinates or proceed without them
            if let coordinate = selectedCoordinate {
                print("📍 Using existing coordinates:")
                print("📍 Latitude: \(coordinate.latitude)")
                print("📍 Longitude: \(coordinate.longitude)")
            } else {
                print("⚠️ No address provided - proceeding without coordinates")
            }
            proceedWithSave()
        }
    }
    
    /// Convert an address string to coordinates using MapKit
    private func convertAddressToCoordinates(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("🚨 Geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                print("🚨 No valid location found for address: \(address)")
                completion(nil)
                return
            }
            
            completion(location.coordinate)
        }
    }
    
    /// Proceed with saving the tool to the backend
    private func proceedWithSave() {
        fetchUsers { users in
            guard let match = users.first(where: { $0.username == username }) else {
                print("❌ User not found: \(self.username)")
                return
            }
            
            let ownerId = match.id
            let latitude = self.selectedCoordinate?.latitude
            let longitude = self.selectedCoordinate?.longitude
            
            print("🚀 Sending tool to backend...")
            print("📝 Tool name: \(self.name)")
            print("💰 Price: $\(String(format: "%.1f", self.price))")
            print("👤 Owner ID: \(ownerId)")
            if let lat = latitude, let lng = longitude {
                print("📍 Coordinates: (\(lat), \(lng))")
            } else {
                print("📍 No coordinates available")
            }
            
            createTool(
                name: self.name,
                price: String(format: "%.1f", self.price),
                description: self.description,
                ownerId: ownerId,
                latitude: latitude,
                longitude: longitude,
                image: self.selectedImage
            ) { success in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Tool created successfully!")
                        // Show success animation
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.showSaveSuccess = true
                        }
                        
                        // Reset form and navigate back after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.name = ""
                            self.price = 0.0
                            self.description = ""
                            self.address = ""
                            self.selectedCoordinate = nil
                            self.selectedImage = nil
                            self.selection = self.previousSelection
                            self.showSaveSuccess = false
                        }
                    } else {
                        print("❌ Failed to create tool")
                    }
                }
            }
        }
    }
    
    /// Cancel the form, reset all fields, and return to the previous view.
    private func cancelPost() {
        // Reset all form fields
        name = ""
        price = 0.0
        description = ""
        address = ""
        selectedCoordinate = nil
        selectedImage = nil
        showSaveSuccess = false
        
        // Navigate back to previous view
        selection = previousSelection
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
                    .foregroundColor(.white)
                
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
            
            ZStack(alignment: .leading) {
                TextField("", text: $text)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .dismissKeyboardOnSwipeDown()
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
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



#Preview {
    PostView(showLogin: .constant(false), showSignUp: .constant(false), selection: .constant(2), previousSelection: .constant(0))
}

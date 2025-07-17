import SwiftUI
import MapKit

struct EditToolView: View {
    /// The tool to edit
    let tool: Tool
    /// Controls presentation of the view
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    /// Callback when tool is successfully updated
    let onToolUpdated: () -> Void
    
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
    @State private var isUpdating = false
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US") // U.S. Dollar
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    var body: some View {
        ZStack {
            ZStack(alignment: .top) {
                // Header - positioned at the very top
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Tool")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Update your tool listing")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
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
                                        
                                        // Image preview - show existing image or selected new image
                                        if let selectedImage = selectedImage {
                                            // New image selected
                                            Image(uiImage: selectedImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxHeight: 200)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                )
                                        } else if let imageUrl = tool.image_url, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                                            // Show existing tool image
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(maxHeight: 200)
                                                        .cornerRadius(12)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                        )
                                                case .failure(_):
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(height: 120)
                                                        .overlay(
                                                            VStack(spacing: 8) {
                                                                Image(systemName: "exclamationmark.triangle")
                                                                    .font(.system(size: 20))
                                                                    .foregroundColor(.orange.opacity(0.7))
                                                                Text("Failed to load")
                                                                    .font(.caption2)
                                                                    .foregroundColor(.gray.opacity(0.8))
                                                            }
                                                        )
                                                case .empty:
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(height: 120)
                                                        .overlay(
                                                            ProgressView()
                                                                .tint(.orange)
                                                        )
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                        }
                                        
                                        // Image picker button - conditional text based on existing image
                                        Button(action: {
                                            showingImageSourceSelection = true
                                        }) {
                                            HStack {
                                                Image(systemName: hasExistingImage() ? "photo.badge.arrow.down" : "photo.badge.plus")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.white)
                                                
                                                Text(hasExistingImage() ? "Change Photo" : "Add Photo")
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
                            
                            // Update Button
                            Button(action: {
                                updateTool()
                            }) {
                                HStack {
                                    if isUpdating {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                        Text("Updating...")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    } else if showSaveSuccess {
                                        Image(systemName: "checkmark")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    } else {
                                        Text("Update Tool")
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
                            .disabled(name.isEmpty || description.isEmpty || price <= 0 || isUpdating)
                            .opacity(name.isEmpty || description.isEmpty || price <= 0 || isUpdating ? 0.6 : 1)
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
                    loadToolData()
                    withAnimation(.easeOut(duration: 0.6)) {
                        isFormVisible = true
                    }
                }
            } // Close ZStack
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    
    /// Check if the tool has an existing image (either original or newly selected)
    private func hasExistingImage() -> Bool {
        return selectedImage != nil || (tool.image_url != nil && !tool.image_url!.isEmpty)
    }
    
    /// Load the tool's existing data into the form fields
    private func loadToolData() {
        name = tool.name
        description = tool.description ?? ""
        price = Double(tool.price) ?? 0.0
        
        // Set coordinates if available and reverse geocode to get address
        if let lat = tool.latitude, let lng = tool.longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            selectedCoordinate = coordinate
            
            // Reverse geocode coordinates to get address
            reverseGeocodeCoordinates(coordinate: coordinate) { addressString in
                DispatchQueue.main.async {
                    if let addressString = addressString {
                        self.address = addressString
                    }
                }
            }
        }
    }
    
    /// Update the tool with the new data
    private func updateTool() {
        isUpdating = true
        
        // Convert address to coordinates if we don't have them yet and address was changed
        if !address.isEmpty && selectedCoordinate == nil {
            print("🔍 Converting address to coordinates: \(address)")
            convertAddressToCoordinates(address: address) { coordinate in
                DispatchQueue.main.async {
                    if let coordinate = coordinate {
                        self.selectedCoordinate = coordinate
                        print("✅ Address converted successfully!")
                        print("📍 Latitude: \(coordinate.latitude)")
                        print("📍 Longitude: \(coordinate.longitude)")
                        self.proceedWithUpdate()
                    } else {
                        print("❌ Failed to convert address to coordinates")
                        // Proceed without coordinates
                        self.proceedWithUpdate()
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
            proceedWithUpdate()
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
    
    /// Convert coordinates to address string using reverse geocoding
    private func reverseGeocodeCoordinates(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("🚨 Reverse geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("🚨 No placemark found for coordinates")
                completion(nil)
                return
            }
            
            // Format the address string
            var addressComponents: [String] = []
            
            if let subThoroughfare = placemark.subThoroughfare {
                addressComponents.append(subThoroughfare)
            }
            if let thoroughfare = placemark.thoroughfare {
                addressComponents.append(thoroughfare)
            }
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            if let administrativeArea = placemark.administrativeArea {
                addressComponents.append(administrativeArea)
            }
            if let postalCode = placemark.postalCode {
                addressComponents.append(postalCode)
            }
            
            let addressString = addressComponents.joined(separator: ", ")
            print("🏠 Reverse geocoded address: \(addressString)")
            completion(addressString)
        }
    }
    
    /// Proceed with updating the tool to the backend
    private func proceedWithUpdate() {
        let latitude = self.selectedCoordinate?.latitude
        let longitude = self.selectedCoordinate?.longitude
        
        print("🚀 Updating tool in backend...")
        print("📝 Tool name: \(self.name)")
        print("💰 Price: $\(String(format: "%.1f", self.price))")
        print("🆔 Tool ID: \(tool.id)")
        if let lat = latitude, let lng = longitude {
            print("📍 Coordinates: (\(lat), \(lng))")
        } else {
            print("📍 No coordinates available")
        }
        
        updateToolInBackend(
            toolId: tool.id,
            name: self.name,
            price: String(format: "%.1f", self.price),
            description: self.description,
            latitude: latitude,
            longitude: longitude,
            image: self.selectedImage
        ) { success in
            DispatchQueue.main.async {
                self.isUpdating = false
                if success {
                    print("✅ Tool updated successfully!")
                    // Show success animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showSaveSuccess = true
                    }
                    
                    // Call the callback and navigate back after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.onToolUpdated()
                        self.dismiss()
                        self.showSaveSuccess = false
                    }
                } else {
                    print("❌ Failed to update tool")
                }
            }
        }
    }

}

#Preview {
    EditToolView(
        tool: Tool(
            id: 1,
            name: "Power Drill",
            price: "15.0",
            description: "High-quality cordless drill with multiple bits.",
            owner_id: 1,
            owner_username: "daniel",
            owner_email: "daniel@example.com",
            owner_first_name: "Daniel",
            owner_last_name: "Flores",
            image_url: "https://images.pexels.com/photos/3970342/pexels-photo-3970342.jpeg",
            latitude: 30.2672,
            longitude: -97.7431
        ),
        isPresented: .constant(true),
        onToolUpdated: {}
    )
} 
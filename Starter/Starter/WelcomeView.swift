import SwiftUI
import CoreLocation

struct WelcomeView: View {
    let username: String
    @State private var tools: [Tool] = []
    @State private var filteredTools: [Tool] = []
    @State private var selectedView = 0
    @State private var isLoading = false
    @StateObject private var locationManager = LocationManager()
    
    // Filter states
    @State private var showFilters = false
    @State private var minPrice: Double = 10
    @State private var maxPrice: Double = 10000
    @State private var selectedDistanceRange: DistanceRange = .all
    
    enum DistanceRange: CaseIterable {
        case ten, twentyFive, fifty, hundred, all
        
        var title: String {
            switch self {
            case .ten: return "10 miles"
            case .twentyFive: return "25 miles"
            case .fifty: return "50 miles"
            case .hundred: return "100 miles"
            case .all: return "All"
            }
        }
        
        var maxDistance: Double? {
            switch self {
            case .ten: return 10 * 1609.34 // Convert miles to meters
            case .twentyFive: return 25 * 1609.34
            case .fifty: return 50 * 1609.34
            case .hundred: return 100 * 1609.34
            case .all: return nil
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header section with modern design
                VStack(spacing: 20) {
                    // Header spacing
                    Spacer()
                        .frame(height: 50)
                    
                    // Header with filter button
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Explore Available Tools")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                            
                            // Active filters indicator
                            if hasActiveFilters {
                                Text("Filters applied")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // Filter button
                        Button(action: {
                            showFilters = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Filters")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                hasActiveFilters ? 
                                Color.white.opacity(0.3) : 
                                Color.black.opacity(0.2)
                            )
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Modern segmented control
                    VStack(spacing: 12) {
                        HStack(spacing: 0) {
                            ForEach(0..<2) { index in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedView = index
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: index == 0 ? "list.bullet" : "map")
                                            .font(.system(size: 16, weight: .medium))
                                        Text(index == 0 ? "List" : "Map")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(selectedView == index ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedView == index ?
                                        Color.white.opacity(0.9) :
                                        Color.clear
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(4)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 30)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Content section
                if selectedView == 0 {
                    ZStack {
                        if isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.orange)
                                Text("Finding the perfect tools for you...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                        } else if filteredTools.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: tools.isEmpty ? "wrench.and.screwdriver" : "magnifyingglass")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.6))
                                Text(tools.isEmpty ? "No tools available" : "No tools match your filters")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                Text(tools.isEmpty ? "Check back later for new listings" : "Try adjusting your filter settings")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.8))
                                
                                if !tools.isEmpty {
                                    Button("Clear Filters") {
                                        clearFilters()
                                    }
                                    .foregroundColor(.orange)
                                    .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredTools) { tool in
                                        NavigationLink(destination: ToolDetailView(tool: tool)) {
                                            ToolCard(tool: tool, userLocation: locationManager.location)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 100) // Extra padding for tab bar
                            }
                            .background(Color(.systemBackground))
                        }
                    }
                } else {
                    MapView()
                        .navigationBarHidden(true)
                        .background(Color(.systemBackground))
                }
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .onAppear {
            loadTools()
        }
        .onReceive(locationManager.$location) { _ in
            // Re-apply filters and sorting when user location changes
            applyFiltersAndSort()
        }
        .sheet(isPresented: $showFilters) {
            FilterView(
                minPrice: $minPrice,
                maxPrice: $maxPrice,
                selectedDistanceRange: $selectedDistanceRange,
                onApply: {
                    applyFiltersAndSort()
                    showFilters = false
                },
                onReset: {
                    clearFilters()
                    showFilters = false
                }
            )
        }
    }
    
    private var hasActiveFilters: Bool {
        minPrice > 10 || maxPrice < 10000 || selectedDistanceRange != .all
    }
    
    private func loadTools() {
        isLoading = true
        fetchTools { fetched in
            DispatchQueue.main.async {
                self.tools = fetched
                self.applyFiltersAndSort()
                self.isLoading = false
            }
        }
    }
    
    private func applyFiltersAndSort() {
        let filtered = filterTools(tools)
        let sorted = sortToolsByDistance(filtered)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            self.filteredTools = sorted
        }
    }
    
    private func clearFilters() {
        minPrice = 10
        maxPrice = 10000
        selectedDistanceRange = .all
        applyFiltersAndSort()
    }
    
    private func filterTools(_ tools: [Tool]) -> [Tool] {
        return tools.filter { tool in
            // Price filter
            guard let price = Double(tool.price),
                  price >= minPrice && price <= maxPrice else {
                return false
            }
            
            // Distance filter
            if selectedDistanceRange != .all,
               let maxDistance = selectedDistanceRange.maxDistance,
               let userLocation = locationManager.location {
                let distance = calculateDistance(from: CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude), to: tool)
                if let toolDistance = distance {
                    return toolDistance <= maxDistance
                } else {
                    // If tool doesn't have location data, exclude it from distance-filtered results
                    return false
                }
            }
            
            return true
        }
    }
    
    /// Sort tools by distance from user's location
    /// Tools without location data or when user location is unavailable will appear at the end
    private func sortToolsByDistance(_ tools: [Tool]) -> [Tool] {
        guard let userLocation = locationManager.location else {
            // If user location is not available, return tools in original order
            print("WelcomeView: User location not available, showing tools in original order")
            return tools
        }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        return tools.sorted { tool1, tool2 in
            let distance1 = calculateDistance(from: userCLLocation, to: tool1)
            let distance2 = calculateDistance(from: userCLLocation, to: tool2)
            
            // Handle cases where distance calculation fails
            switch (distance1, distance2) {
            case (.some(let d1), .some(let d2)):
                return d1 < d2 // Sort by distance, closest first
            case (.some(_), .none):
                return true // Tool with valid location comes first
            case (.none, .some(_)):
                return false // Tool with valid location comes first
            case (.none, .none):
                return false // Maintain original order if both lack location data
            }
        }
    }
    
    /// Calculate distance between user location and a tool
    /// Returns nil if tool doesn't have valid coordinates
    private func calculateDistance(from userLocation: CLLocation, to tool: Tool) -> Double? {
        guard let toolLatitude = tool.latitude,
              let toolLongitude = tool.longitude else {
            return nil
        }
        
        let toolLocation = CLLocation(latitude: toolLatitude, longitude: toolLongitude)
        return userLocation.distance(from: toolLocation) // Returns distance in meters
    }
}

struct ToolCard: View {
    let tool: Tool
    let userLocation: CLLocationCoordinate2D?
    
    private var formattedPrice: String {
        guard let price = Double(tool.price) else {
            return tool.price // Return original string if conversion fails
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: price)) ?? tool.price
    }
    
    private var distanceText: String? {
        guard let userLocation = userLocation,
              let toolLatitude = tool.latitude,
              let toolLongitude = tool.longitude else {
            return nil
        }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let toolLocation = CLLocation(latitude: toolLatitude, longitude: toolLongitude)
        let distance = userCLLocation.distance(from: toolLocation) // Distance in meters
        
        // Convert to miles for display
        let distanceInMiles = distance * 0.000621371
        
        if distanceInMiles < 0.1 {
            return "< 0.1 mi"
        } else if distanceInMiles < 1.0 {
            return String(format: "%.1f mi", distanceInMiles)
        } else {
            return String(format: "%.0f mi", distanceInMiles)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section
            ZStack {
                if let imageUrl = tool.image_url, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure(_):
                            // Image failed to load
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 30))
                                            .foregroundColor(.orange.opacity(0.7))
                                        Text("Failed to load")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                )
                        case .empty:
                            // Still loading
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .tint(.orange)
                                        Text("Loading...")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "wrench.and.screwdriver")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray.opacity(0.6))
                                Text("No Image")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                        )
                }
                
                // Price overlay
                VStack {
                    HStack {
                        Spacer()
                        Text("$\(formattedPrice)/day")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(12)
            }
            
            // Content section
            VStack(alignment: .leading, spacing: 12) {
                Text(tool.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let description = tool.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Owner info and distance
                HStack {
                    if let ownerName = tool.owner_username {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.7))
                            Text("by \(ownerName)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Distance badge
                    if let distance = distanceText {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text(distance)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    WelcomeView(username: "John")
}

struct FilterView: View {
    @Binding var minPrice: Double
    @Binding var maxPrice: Double
    @Binding var selectedDistanceRange: WelcomeView.DistanceRange
    
    let onApply: () -> Void
    let onReset: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                // Price Range Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Price Range")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Filter tools by daily rental price")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                    
                    VStack(spacing: 12) {
                        // Price range display
                        HStack {
                            Text("$\(Int(minPrice))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Text("to")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("$\(Int(maxPrice))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        // Price range sliders
                        VStack(spacing: 8) {
                            // Min price slider
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Minimum Price: $\(Int(minPrice))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $minPrice, in: 10...min(maxPrice, 10000), step: 5)
                                    .tint(.orange)
                            }
                            
                            // Max price slider
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Maximum Price: $\(Int(maxPrice))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $maxPrice, in: max(minPrice, 10)...10000, step: 5)
                                    .tint(.orange)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Distance Range Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Distance Range")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Filter tools by distance from your location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(WelcomeView.DistanceRange.allCases, id: \.self) { range in
                            Button(action: {
                                selectedDistanceRange = range
                            }) {
                                HStack {
                                    Text(range.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedDistanceRange == range ? .white : .primary)
                                    
                                    Spacer()
                                    
                                    if selectedDistanceRange == range {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    selectedDistanceRange == range ?
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(.systemBackground), Color(.systemBackground)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedDistanceRange == range ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onApply) {
                        Text("Apply Filters")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    
                    Button(action: onReset) {
                        Text("Reset Filters")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40) // Extra bottom padding for safe area
            }
        }
        .background(Color(.systemBackground))
    }
}

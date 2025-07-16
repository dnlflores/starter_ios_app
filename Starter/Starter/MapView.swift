import SwiftUI
import MapKit

/// Custom annotation for displaying tools on the map
struct ToolAnnotation: Identifiable {
    let id: Int
    let name: String
    let price: String
    let description: String?
    let coordinate: CLLocationCoordinate2D
    let tool: Tool
    
    init(tool: Tool) {
        self.id = tool.id
        self.name = tool.name
        self.price = tool.price
        self.description = tool.description
        self.coordinate = CLLocationCoordinate2D(
            latitude: tool.latitude ?? 0,
            longitude: tool.longitude ?? 0
        )
        self.tool = tool
    }
}

/// Displays a map centered on the user's location when first shown.
///
/// After the initial centering the user is free to pan/zoom the map
/// without it snapping back to their current position.
struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    /// Tracks whether we've already centered the map on the user's location.
    @State private var hasCentered = false
    /// Tools to display on the map
    @State private var tools: [Tool] = []
    /// Tool annotations for the map
    @State private var toolAnnotations: [ToolAnnotation] = []
    /// Selected tool for showing details
    @State private var selectedTool: Tool? = nil

    var body: some View {
        Map(position: $position) {
            // Show user location
            UserAnnotation()
            
            // Show tool annotations
            ForEach(toolAnnotations) { annotation in
                Annotation(annotation.name, coordinate: annotation.coordinate) {
                    VStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                        
                        Text(formatPrice(annotation.price))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 2)
                    }
                    .onTapGesture {
                        selectedTool = annotation.tool
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            fetchToolsForMap()
        }
        .onReceive(locationManager.$location) { location in
            // Only center on the user's location the first time we obtain it.
            if let location, !hasCentered {
                position = .region(
                    MKCoordinateRegion(
                        center: location,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
                hasCentered = true
            }
        }
        .sheet(item: $selectedTool) { tool in
            ToolDetailView(tool: tool)
                .presentationDetents([.medium])
        }
    }
    
    /// Fetch tools from the server and create annotations
    private func fetchToolsForMap() {
        fetchTools { fetchedTools in
            DispatchQueue.main.async {
                // Filter tools that have valid coordinates
                let toolsWithCoordinates = fetchedTools.filter { tool in
                    tool.latitude != nil && tool.longitude != nil
                }
                
                self.tools = toolsWithCoordinates
                self.toolAnnotations = toolsWithCoordinates.map { ToolAnnotation(tool: $0) }
                
                print("MapView: Loaded \(self.toolAnnotations.count) tools with coordinates")
            }
        }
    }
    
    /// Formats price string to proper currency display
    private func formatPrice(_ priceString: String) -> String {
        guard let price = Double(priceString) else {
            return "$\(priceString)"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: price)) ?? "$\(priceString)"
    }
}

#Preview {
    MapView()
}

import SwiftUI
import MapKit

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

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
        }
        .edgesIgnoringSafeArea(.all)
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
    }
}

#Preview {
    MapView()
}

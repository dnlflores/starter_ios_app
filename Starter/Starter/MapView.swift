import SwiftUI
import MapKit

/// Displays a map that follows the user's current location.
struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            .edgesIgnoringSafeArea(.all)
            .onReceive(locationManager.$location) { location in
                if let location {
                    region.center = location
                }
            }
    }
}

#Preview {
    MapView()
}

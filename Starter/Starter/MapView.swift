import SwiftUI
import MapKit

/// Displays a map that follows the user's current location.
struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = .black
            navAppearance.titleTextAttributes = [.foregroundColor: UIColor.orange]
            navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.orange]
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().compactAppearance = navAppearance
        }
        .onDisappear {
            // Keep global black navigation bar style when leaving the map view.
        }
        .onReceive(locationManager.$location) { location in
            if let location {
                withAnimation {
                    position = .region(
                        MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
            }
        }
    }
}

#Preview {
    MapView()
}

import SwiftUI
import MapKit

struct AddressSearchField: View {
    @ObservedObject var service: AddressSearchService
    @Binding var selectedAddress: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @StateObject private var keyboard = KeyboardResponder()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .leading) {
                TextField("", text: $service.query)
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 18)
                if service.query.isEmpty {
                    Text("Address")
                        .foregroundColor(.gray.opacity(0.4))
                        .padding(.horizontal, 26)
                }
            }
            if !service.results.isEmpty && service.query != selectedAddress {
                List(service.results, id: \.self) { completion in
                    VStack(alignment: .leading) {
                        Text(completion.title)
                            .foregroundColor(.white)
                        if !completion.subtitle.isEmpty {
                            Text(completion.subtitle)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .listRowBackground(Color.black.opacity(0.6))
                    .onTapGesture {
                        select(completion)
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 150)
            }
        }
        .padding(.bottom, keyboard.keyboardHeight)
    }

    private func select(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            if let coordinate = response?.mapItems.first?.placemark.coordinate {
                DispatchQueue.main.async {
                    self.selectedCoordinate = coordinate
                    self.selectedAddress = completion.title + (completion.subtitle.isEmpty ? "" : ", \(completion.subtitle)")
                    service.query = self.selectedAddress
                    service.results = []
                }
            }
        }
    }
}

#Preview {
    AddressSearchField(service: AddressSearchService(), selectedAddress: .constant(""), selectedCoordinate: .constant(nil))
        .applyThemeBackground()
}

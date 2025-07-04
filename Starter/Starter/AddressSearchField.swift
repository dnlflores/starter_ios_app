import SwiftUI
import MapKit

struct AddressSearchField: View {
    @ObservedObject var service: AddressSearchService
    @Binding var selectedAddress: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(service.results, id: \.self) { completion in
                            VStack(alignment: .leading) {
                                Text(completion.title)
                                    .foregroundColor(.white)
                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.6))
                            .onTapGesture {
                                select(completion)
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
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

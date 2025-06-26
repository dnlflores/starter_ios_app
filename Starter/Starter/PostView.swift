import SwiftUI
import MapKit

struct PostView: View {
    /// Controls presentation of the login sheet from the parent view.
    @Binding var showLogin: Bool
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
    @StateObject private var addressSearch = AddressSearchService()
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var latitude: Double?
    @State private var longitude: Double?
    
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
                VStack(spacing: 16) {
                    Text("You are not logged in.")
                        .font(.title2)
                    Button("Log In") {
                        showLogin = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
            } else {
                NavigationStack {
                    VStack (spacing: 16){
                        Text("New Listing")
                            .font(.title)
                            .bold()
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        VStack {
                            ZStack {
                                TextField("", text: $name)
                                    .padding()
                                    .background(.black.opacity(0.4))
                                    .foregroundColor(.white)
                                    .cornerRadius(8.0)
                                    .padding(.horizontal, 18)
                                if name.isEmpty {
                                    Text("Tool Name")
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            }
                            .padding(.top, 16)
                            ZStack {
                                TextEditor(text: $description)
                                    .padding()
                                    .scrollContentBackground(.hidden)
                                    .background(.black.opacity(0.4))
                                    .cornerRadius(8)
                                    .frame(width: 365, height: 150)
                                    .foregroundColor(.white)
                                if description.isEmpty {
                                    Text("Tool Description")
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            }
                            ZStack {
                                TextField("", text: $addressSearch.query)
                                    .padding()
                                    .background(.black.opacity(0.4))
                                    .foregroundColor(.white)
                                    .cornerRadius(8.0)
                                    .padding(.horizontal, 18)
                                if addressSearch.query.isEmpty {
                                    Text("Address")
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            }
                            if !addressSearch.results.isEmpty && !addressSearch.query.isEmpty {
                                List(addressSearch.results) { result in
                                    VStack(alignment: .leading) {
                                        Text(result.title)
                                            .font(.body)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        addressSearch.query = result.title + (result.subtitle.isEmpty ? "" : ", \(result.subtitle)")
                                        addressSearch.coordinate(for: result) { coord in
                                            selectedCoordinate = coord
                                            latitude = coord?.latitude
                                            longitude = coord?.longitude
                                        }
                                        addressSearch.results = []
                                    }
                                }
                                .listStyle(.plain)
                                .frame(maxHeight: 150)
                            }
                            if let lat = latitude, let lon = longitude {
                                Text("Lat: \(lat), Lon: \(lon)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                            }
                            Text("Price")
                                .font(.system(size: 18))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 0)
                                .padding(.top, 8)
                                .bold()
                            TextField("", value: $price, formatter: currencyFormatter)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(.black.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(8.0)
                                .padding(.horizontal, 18)
                        }
                        Button(action: {
                            savePost()
                        }) {
                            Text("Save")
                                .padding(8)
                                .frame(width: 200)
                        }
                        .font(.title)
                        .background(Color.black.opacity(0.4))
                        .shadow(radius: 8)
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .applyThemeBackground()
                    .tint(.purple)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancel") {
                                selection = previousSelection
                            }
                            .foregroundStyle(Color.red)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Save") {
                                savePost()
                            }
                            .foregroundStyle(Color.purple)
                            .bold()
                            .font(.title3)
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
        fetchUsers { users in
            guard let match = users.first(where: { $0.username == username }) else {
                return
            }
            let ownerId = match.id
            let createdAt = ISO8601DateFormatter().string(from: Date())
            createTool(name: name, price: price, description: description, ownerId: ownerId, createdAt: createdAt, authToken: authToken) { success in
                if success {
                    DispatchQueue.main.async {
                        name = ""
                        price = 0.0
                        description = ""
                        selection = previousSelection
                    }
                }
            }
        }
    }
}

#Preview {
    PostView(showLogin: .constant(false), selection: .constant(2), previousSelection: .constant(0))
}

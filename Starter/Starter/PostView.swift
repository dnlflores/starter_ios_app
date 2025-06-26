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
    @State private var addressQuery = ""
    @StateObject private var searchCompleter = MKLocalSearchCompleter()
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    
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
                                TextField("", text: $addressQuery)
                                    .padding()
                                    .background(.black.opacity(0.4))
                                    .foregroundColor(.white)
                                    .cornerRadius(8.0)
                                    .padding(.horizontal, 18)
                                    .onChange(of: addressQuery) { newValue in
                                        searchCompleter.queryFragment = newValue
                                    }
                                if addressQuery.isEmpty {
                                    Text("Address")
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            }
                            if !searchResults.isEmpty {
                                List(searchResults.indices, id: \.self) { index in
                                    let result = searchResults[index]
                                    VStack(alignment: .leading) {
                                        Text(result.title)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .onTapGesture {
                                        selectCompletion(result)
                                    }
                                }
                                .frame(maxHeight: 150)
                                .listStyle(.plain)
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
        .onAppear {
            searchCompleter.resultTypes = .address
        }
        .onReceive(searchCompleter.$results) { results in
            searchResults = results
        }
    }

    /// Perform a search using the selected completion to obtain coordinates.
    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            if let item = response?.mapItems.first {
                selectedCoordinate = item.placemark.coordinate
                addressQuery = completion.title + ", " + completion.subtitle
                searchResults.removeAll()
            }
        }
    }

    /// Save the entered data to the server and return to the previous tab on success.
    private func savePost() {
        fetchUsers { users in
            guard let match = users.first(where: { $0.username == username }) else {
                return
            }
            let ownerId = match.id
            let createdAt = ISO8601DateFormatter().string(from: Date())
            createTool(name: name,
                       price: price,
                       description: description,
                       ownerId: ownerId,
                       createdAt: createdAt,
                       latitude: selectedCoordinate?.latitude,
                       longitude: selectedCoordinate?.longitude,
                       authToken: authToken) { success in
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

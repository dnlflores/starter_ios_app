import SwiftUI
import MapKit

struct AddressSearchField: View {
    @ObservedObject var service: AddressSearchService
    @Binding var selectedAddress: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    
    @State private var isSearching = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Input field that shows selected address or placeholder
            Button(action: {
                searchText = selectedAddress.isEmpty ? "" : selectedAddress
                service.query = searchText
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSearching = true
                }
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16))
                    
                    Text(selectedAddress.isEmpty ? "Where is your tool located?" : selectedAddress)
                        .foregroundColor(selectedAddress.isEmpty ? .white.opacity(0.6) : .white)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .fullScreenCover(isPresented: $isSearching) {
            AddressSearchModal(
                service: service,
                searchText: $searchText,
                selectedAddress: $selectedAddress,
                selectedCoordinate: $selectedCoordinate,
                isSearching: $isSearching
            )
        }
    }
}

struct AddressSearchModal: View {
    @ObservedObject var service: AddressSearchService
    @Binding var searchText: String
    @Binding var selectedAddress: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var isSearching: Bool
    
    @State private var animateIn = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 0) {
                headerView
                resultsView
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTextFieldFocused = true
            }
        }
    }
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.red, Color.orange]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            navigationBar
            searchField
        }
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.black.opacity(0.1))
                .blur(radius: 10)
        )
        .offset(y: animateIn ? 0 : -100)
        .opacity(animateIn ? 1 : 0)
    }
    
    private var navigationBar: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSearching = false
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Add Location")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                searchText = ""
                service.query = ""
            }) {
                Text("Clear")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .opacity(searchText.isEmpty ? 0 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var searchField: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 18))
                
                TextField("Search for an address or location", text: $searchText)
                    .focused($isTextFieldFocused)
                    .font(.body)
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .onChange(of: searchText) { _, newValue in
                        service.query = newValue
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.2))
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
    
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if service.results.isEmpty && !searchText.isEmpty {
                    noResultsView
                } else if searchText.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(service.results.enumerated()), id: \.offset) { index, completion in
                        AddressResultRow(
                            completion: completion,
                            index: index,
                            animateIn: animateIn
                        ) {
                            select(completion)
                        }
                    }
                }
            }
        }
        .offset(y: animateIn ? 0 : 50)
        .opacity(animateIn ? 1 : 0)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No locations found")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Try searching for a different address or location")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Search for your location")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Type in the address where your tool is located")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
    
    private func select(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            if let coordinate = response?.mapItems.first?.placemark.coordinate {
                DispatchQueue.main.async {
                    self.selectedCoordinate = coordinate
                    self.selectedAddress = completion.title + (completion.subtitle.isEmpty ? "" : ", \(completion.subtitle)")
                    
                    // Clear search and close modal
                    service.query = ""
                    service.results = []
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSearching = false
                    }
                }
            }
        }
    }
}

struct AddressResultRow: View {
    let completion: MKLocalSearchCompletion
    let index: Int
    let animateIn: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Location icon
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "location")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
                
                // Address info
                VStack(alignment: .leading, spacing: 4) {
                    Text(completion.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    if !completion.subtitle.isEmpty {
                        Text(completion.subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: animateIn)
    }
}

#Preview {
    AddressSearchField(
        service: AddressSearchService(),
        selectedAddress: .constant(""),
        selectedCoordinate: .constant(nil)
    )
    .applyThemeBackground()
}

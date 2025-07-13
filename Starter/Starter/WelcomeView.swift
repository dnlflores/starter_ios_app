import SwiftUI

struct WelcomeView: View {
    let username: String
    @State private var tools: [Tool] = []
    @State private var selectedView = 0
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    VStack {
                        Picker("View", selection: $selectedView) {
                            Text("List").tag(0)
                            Text("Map").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        .background(Color.black)
                        .tint(.purple)
                    }
                    .background(Color.black)
                    
                    
                    // 2) Now show either the List or the Map below it
                    if selectedView == 0 {
                        List(tools) { tool in
                            NavigationLink(destination: ToolDetailView(tool: tool)) {
                                VStack(alignment: .leading) {
                                    Text(tool.name)
                                        .font(.headline)
                                    Text(truncateText(tool.description ?? "No description available", maxLength: 50))
                                        .font(.subheadline)
                                    HStack {
                                        Text("$\(tool.price) / day")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .bold()
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(5)
                                        Spacer()
                                    }
                                }
                            }
                            .listRowBackground(
                                Color.clear
                            )
                        }
                        .listStyle(.plain)
                        .padding(.bottom, 84)
                        .ignoresSafeArea()
                    } else {
                        MapView()
                            .toolbarBackground(Color.black, for: .navigationBar)
                            .toolbarColorScheme(.light, for: .navigationBar)
                            .toolbarBackground(Color.black, for: .tabBar)
                            .tint(.purple)
                    }
                }
                .applyThemeBackground()
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Text("RNTL")
                            .font(.largeTitle)
                            .foregroundColor(.purple)
                            .bold()
                    }
                }
            }
            .onAppear {
                fetchTools { fetched in
                    DispatchQueue.main.async {
                        self.tools = fetched
                    }
                }
            }
        }
    }
    
    // Helper function to truncate text to specified length
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        } else {
            return String(text.prefix(maxLength)) + "..."
        }
    }
}

#Preview {
    WelcomeView(username: "User")
}

import SwiftUI

struct WelcomeView: View {
    let username: String
    @State private var tools: [Tool] = []
    @State private var selectedView = 0
    @State private var isLoading = false
    
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
                        .background(.black)
                        .tint(.white)
                    }
                    .background(.black)
                    
                    
                    // 2) Now show either the List or the Map below it
                    if selectedView == 0 {
                        ZStack {
                            List(tools) { tool in
                                NavigationLink(destination: ToolDetailView(tool: tool)) {
                                    VStack(alignment: .leading) {
                                        Text(tool.name)
                                            .font(.headline)
                                        Text(truncateText(tool.description ?? "No description available", maxLength: 80))
                                            .font(.subheadline)
                                        HStack {
                                            Text("$\(tool.price) / day")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                                .bold()
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(Color.black.opacity(0.5))
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
                            
                            // Loading indicator
                            if isLoading || tools.isEmpty {
                                ProgressView("Loading available tools...")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.black.opacity(0.3))
                            }
                        }
                    } else {
                        MapView()
                            .toolbarBackground(Color.black, for: .navigationBar)
                            .toolbarColorScheme(.light, for: .navigationBar)
                            .toolbarBackground(Color.black, for: .tabBar)
                            .tint(.orange)
                    }
                }
                .applyThemeBackground()
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Text("RNTL")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                            .bold()
                    }
                }
            }
            .onAppear {
                loadTools()
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
    
    // Load tools with loading state management
    private func loadTools() {
        isLoading = true
        fetchTools { fetched in
            DispatchQueue.main.async {
                self.tools = fetched
                self.isLoading = false
            }
        }
    }
}

#Preview {
    WelcomeView(username: "User")
}

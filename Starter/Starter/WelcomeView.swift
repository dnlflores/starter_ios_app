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
                        .tint(.orange)
                    }
                    .background(Color.black)
                    .frame(height: 60)
                    
                    
                    // 2) Now show either the List or the Map below it
                    if selectedView == 0 {
                        List(tools) { tool in
                            NavigationLink(destination: ToolDetailView(tool: tool)) {
                                VStack(alignment: .leading) {
                                    Text(tool.name)
                                        .font(.headline)
                                    Text(tool.description ?? "No description available")
                                        .font(.subheadline)
                                }
                            }
                            .listRowBackground(
                                Color.clear
                            )
                        }
                        .listStyle(.plain)
                    } else {
                        // If you keep edgesIgnoringSafeArea on MapView, at least
                        // the Picker above will remain on a plain/blurred background
                        MapView()
                    }
                }
                .applyThemeBackground()
                .navigationTitle("RNTL")
                .navigationBarTitleDisplayMode(.inline)
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
}

#Preview {
    WelcomeView(username: "User")
}

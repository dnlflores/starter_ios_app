import SwiftUI

struct WelcomeView: View {
    let username: String
    @State private var tools: [Tool] = []
    @State private var selectedView = 0
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Welcome, \(username)!")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Picker("View", selection: $selectedView) {
                    Text("List").tag(0)
                    Text("Map").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

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
                    }
                } else {
                    MapView()
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

#Preview {
    WelcomeView(username: "User")
}

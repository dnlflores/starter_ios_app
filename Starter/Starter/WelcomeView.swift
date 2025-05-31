import SwiftUI

struct WelcomeView: View {
    let username: String
    @State private var tools: [Tool] = []
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Welcome, \(username)!")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
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

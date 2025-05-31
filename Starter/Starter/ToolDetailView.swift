import SwiftUI

struct ToolDetailView: View {
    let tool: Tool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(tool.name)
                    .font(.largeTitle)
                    .bold()
                Text(tool.description ?? "No description available")
                Text("Price: \(tool.price)")
                if let owner = tool.owner_id {
                    Text("Owner ID: \(owner)")
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle(tool.name)
    }
}

#Preview {
    ToolDetailView(tool: Tool(id: 1, name: "Hammer", price: "$10", description: "A sturdy hammer.", owner_id: 1))
}

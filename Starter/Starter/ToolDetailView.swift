import SwiftUI

struct ToolDetailView: View {
    let tool: Tool
    @Environment(\.dismiss) private var dismiss

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

                MapView()
                    .frame(height: 200)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("RNTL")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
}

#Preview {
    ToolDetailView(tool: Tool(id: 1, name: "Hammer", price: "$10", description: "A sturdy hammer.", owner_id: 1))
}

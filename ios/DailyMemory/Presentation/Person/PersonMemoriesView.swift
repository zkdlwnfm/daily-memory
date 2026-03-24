import SwiftUI

struct PersonMemoriesView: View {
    let person: Person
    let memories: [Memory]

    var body: some View {
        ScrollView {
            if memories.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No memories with \(person.name)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(memories) { memory in
                        NavigationLink(destination: MemoryDetailView(memoryId: memory.id)) {
                            PersonMemoryCard(memory: memory)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Memories with \(person.name)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PersonMemoryCard: View {
    let memory: Memory

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: memory.recordedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedDate.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.dmPrimary.opacity(0.7))
                .tracking(1)

            Text(memory.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(4)

            if let location = memory.extractedLocation {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.caption2)
                    Text(location)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }
}

#Preview {
    NavigationStack {
        PersonMemoriesView(
            person: Person(name: "Mike", relationship: .friend),
            memories: []
        )
    }
}

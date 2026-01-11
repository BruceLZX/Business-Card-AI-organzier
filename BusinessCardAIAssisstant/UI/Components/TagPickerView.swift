import SwiftUI

struct TagPickerView: View {
    let availableTags: [String]
    @Binding var selectedTags: [String]
    let placeholder: String
    let addLabel: String

    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(availableTags, id: \.self) { tag in
                    TagChip(title: tag, isSelected: selectedTags.contains(tag)) {
                        toggle(tag)
                    }
                }
            }

            HStack {
                TextField(placeholder, text: $newTag)
                    .textInputAutocapitalization(.never)
                Button(addLabel) {
                    addNewTag()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func toggle(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    private func addNewTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !selectedTags.contains(trimmed) {
            selectedTags.append(trimmed)
        }
        newTag = ""
    }
}

private struct TagChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }
}

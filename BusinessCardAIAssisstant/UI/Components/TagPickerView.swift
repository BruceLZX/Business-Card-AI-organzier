import SwiftUI

struct TagPickerView: View {
    let availableTags: [String]
    @Binding var selectedTags: [String]
    let placeholder: String
    let addLabel: String
    let selectLabel: String
    let titleLabel: String
    let doneLabel: String

    @State private var newTag = ""
    @State private var isPresentingPicker = false
    @State private var searchText = ""

    var body: some View {
        content
            .sheet(isPresented: $isPresentingPicker) {
                TagPickerSheet(
                    availableTags: filteredTags,
                    selectedTags: $selectedTags,
                    searchText: $searchText,
                    placeholder: placeholder,
                    titleLabel: titleLabel,
                    doneLabel: doneLabel,
                    onDone: { isPresentingPicker = false }
                )
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            selectedTagsView
            controlsView
        }
    }

    private var selectedTagsView: some View {
        Group {
            if selectedTags.isEmpty {
                Text("—")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(selectedTags, id: \.self) { tag in
                        TagChip(title: tag, isSelected: true) {
                            toggle(tag)
                        }
                    }
                }
            }
        }
    }

    private var controlsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(selectLabel) {
                    isPresentingPicker = true
                }
                .buttonStyle(.bordered)
                Spacer()
                TextField(placeholder, text: $newTag)
                    .textInputAutocapitalization(.never)
            }

            Button(addLabel) {
                addNewTag()
            }
            .buttonStyle(.bordered)
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

    private var filteredTags: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return availableTags }
        return availableTags.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }
}

private struct TagPickerSheet: View {
    struct TagItem: Identifiable {
        let id: String
        let name: String
    }

    let availableTags: [String]
    @Binding var selectedTags: [String]
    @Binding var searchText: String
    let placeholder: String
    let titleLabel: String
    let doneLabel: String
    let onDone: () -> Void

    private var items: [TagItem] {
        availableTags.map { TagItem(id: $0, name: $0) }
    }

    var body: some View {
        NavigationStack {
            TagPickerList(
                items: items,
                selectedTags: $selectedTags,
                toggle: toggle
            )
            .searchable(text: $searchText, prompt: placeholder)
            .navigationTitle(titleLabel)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(doneLabel) {
                        onDone()
                    }
                }
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
}

private struct TagPickerList: View {
    let items: [TagPickerSheet.TagItem]
    @Binding var selectedTags: [String]
    let toggle: (String) -> Void

    var body: some View {
        List(items) { item in
            TagPickerRow(
                name: item.name,
                isSelected: selectedTags.contains(item.name),
                toggle: toggle
            )
        }
    }
}

private struct TagPickerRow: View {
    let name: String
    let isSelected: Bool
    let toggle: (String) -> Void

    var body: some View {
        Button {
            toggle(name)
        } label: {
            HStack {
                Text(name)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
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

import SwiftUI
import UIKit

struct CompanyDetailView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @State private var draft: CompanyDocument
    @State private var editingSection: Section?
    @State private var isPresentingCamera = false
    @State private var showEnrichConfirm = false

    private enum Section {
        case profile
        case details
        case links
        case tags
        case notes
    }

    init(company: CompanyDocument) {
        _draft = State(initialValue: company)
    }

    private var relatedContacts: [ContactDocument] {
        appState.contacts.filter { draft.relatedContactIDs.contains($0.id) }
    }

    private var showEnrichButton: Bool {
        settings.enableEnrichment && draft.enrichedAt == nil
    }

    private var shouldShowOriginalName: Bool {
        if let originalName = draft.originalName, !originalName.isEmpty {
            return true
        }
        guard let sourceLanguageCode = draft.sourceLanguageCode else { return false }
        return sourceLanguageCode != settings.language.languageCode
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if showEnrichButton {
                    Button {
                        showEnrichConfirm = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                            Text(settings.text(.enrichButton))
                                .font(.headline)
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }

                profileSection
                detailsSection
                linksSection
                tagsSection
                contactsSection
                photosSection
                notesSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(settings.text(.company))
        .onAppear {
            if let current = appState.company(for: draft.id) {
                draft = current
            }
        }
        .onReceive(appState.$companies) { _ in
            if let current = appState.company(for: draft.id) {
                draft = current
            }
        }
        .sheet(isPresented: $isPresentingCamera) {
            CameraView { image in
                if let photoID = appState.addCompanyPhoto(companyID: draft.id, image: image) {
                    draft.photoIDs.insert(photoID, at: 0)
                }
            }
        }
        .alert(settings.text(.enrichConfirmTitle), isPresented: $showEnrichConfirm) {
            Button(settings.text(.enrichButton)) {
                appState.enrichCompany(companyID: draft.id)
            }
            Button(settings.text(.cancel), role: .cancel) {}
        } message: {
            Text(settings.text(.enrichConfirmMessage))
        }
    }

    private var profileSection: some View {
        SectionCard(
            title: settings.text(.profile),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: editingSection == .profile,
            showsEdit: true,
            onEdit: { editingSection = .profile },
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            if editingSection == .profile {
                TextField(settings.text(.name), text: $draft.name)
                if shouldShowOriginalName {
                    TextField(settings.text(.originalName), text: binding(for: $draft.originalName))
                }
                TextField(settings.text(.summary), text: $draft.summary, axis: .vertical)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(draft.name.isEmpty ? "—" : draft.name)
                        .font(.title2.bold())
                    if let originalName = draft.originalName,
                       !originalName.isEmpty,
                       originalName != draft.name {
                        Text("\(settings.text(.originalName)): \(originalName)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if !draft.summary.isEmpty {
                        Text(draft.summary)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        SectionCard(
            title: settings.text(.companyDetails),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: editingSection == .details,
            showsEdit: true,
            onEdit: { editingSection = .details },
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            if editingSection == .details {
                TextField(settings.text(.industry), text: binding(for: $draft.industry))
                TextField(settings.text(.companySize), text: binding(for: $draft.companySize))
                TextField(settings.text(.revenue), text: binding(for: $draft.revenue))
                TextField(settings.text(.foundedYear), text: binding(for: $draft.foundedYear))
                TextField(settings.text(.headquarters), text: binding(for: $draft.headquarters))
                TextField(settings.text(.serviceTypeLabel), text: $draft.serviceType)
                TextField(settings.text(.location), text: $draft.location)
                TextField(settings.text(.marketRegionLabel), text: $draft.marketRegion)
                Picker(settings.text(.targetAudience), selection: $draft.targetAudience) {
                    ForEach(TargetAudience.allCases) { option in
                        Text(option.label(language: settings.language)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                InfoGridView(rows: [
                    InfoRow(label: settings.text(.industry), value: draft.industry),
                    InfoRow(label: settings.text(.companySize), value: draft.companySize),
                    InfoRow(label: settings.text(.revenue), value: draft.revenue),
                    InfoRow(label: settings.text(.foundedYear), value: draft.foundedYear),
                    InfoRow(label: settings.text(.headquarters), value: draft.headquarters),
                    InfoRow(label: settings.text(.serviceTypeLabel), value: draft.serviceType),
                    InfoRow(label: settings.text(.location), value: draft.location),
                    InfoRow(label: settings.text(.marketRegionLabel), value: draft.marketRegion),
                    InfoRow(label: settings.text(.targetAudience), value: draft.targetAudience.label(language: settings.language))
                ])
            }
        }
    }

    private var linksSection: some View {
        SectionCard(
            title: settings.text(.links),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: editingSection == .links,
            showsEdit: true,
            onEdit: { editingSection = .links },
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            if editingSection == .links {
                TextField(settings.text(.website), text: $draft.website)
                TextField(settings.text(.linkedin), text: binding(for: $draft.linkedinURL))
                TextField(settings.text(.phone), text: $draft.phone)
                TextField(settings.text(.address), text: $draft.address)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        if let url = draft.websiteURL {
                            LinkLabel(title: settings.text(.website), url: url)
                        }
                        if let url = draft.linkedinURLValue {
                            LinkLabel(title: settings.text(.linkedin), url: url)
                        }
                    }
                    InfoGridView(rows: [
                        InfoRow(label: settings.text(.phone), value: draft.phone),
                        InfoRow(label: settings.text(.address), value: draft.address)
                    ])
                }
            }
        }
    }

    private var tagsSection: some View {
        SectionCard(
            title: settings.text(.tags),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: editingSection == .tags,
            showsEdit: true,
            onEdit: { editingSection = .tags },
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            if editingSection == .tags {
                TagPickerView(
                    availableTags: appState.tagPool,
                    selectedTags: $draft.tags,
                    placeholder: settings.text(.tags),
                    addLabel: settings.text(.addButton)
                )
                .onChange(of: draft.tags) { _, newValue in
                    appState.registerTags(newValue)
                }
            } else {
                TagRowView(tags: draft.tags)
            }
        }
    }

    private var contactsSection: some View {
        SectionCard(
            title: settings.text(.relatedContacts),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: false,
            showsEdit: false,
            onEdit: {},
            onSave: {},
            onCancel: {}
        ) {
            if relatedContacts.isEmpty {
                Text(settings.text(.noRelatedContacts))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(relatedContacts) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.name)
                                        .font(.headline)
                                    Text(contact.title)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var photosSection: some View {
        SectionCard(
            title: settings.text(.photos),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: false,
            showsEdit: false,
            onEdit: {},
            onSave: {},
            onCancel: {}
        ) {
            HStack {
                Spacer()
                Button {
                    isPresentingCamera = true
                } label: {
                    Label(settings.text(.addPhoto), systemImage: "camera")
                }
            }

            if draft.photoIDs.isEmpty {
                Text(settings.text(.noPhotos))
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(draft.photoIDs, id: \.self) { photoID in
                            if let image = appState.loadCompanyPhoto(companyID: draft.id, photoID: photoID) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        SectionCard(
            title: settings.text(.notes),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: editingSection == .notes,
            showsEdit: true,
            onEdit: { editingSection = .notes },
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            if editingSection == .notes {
                TextField(settings.text(.notes), text: $draft.notes, axis: .vertical)
            } else {
                Text(draft.notes.isEmpty ? "—" : draft.notes)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func saveSection() {
        appState.updateCompany(draft)
        editingSection = nil
    }

    private func cancelSection() {
        if let current = appState.company(for: draft.id) {
            draft = current
        }
        editingSection = nil
    }

    private func binding(for value: Binding<String?>) -> Binding<String> {
        Binding(
            get: { value.wrappedValue ?? "" },
            set: { value.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    let editLabel: String
    let saveLabel: String
    let cancelLabel: String
    let isEditing: Bool
    let showsEdit: Bool
    let onEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    if showsEdit {
                        if isEditing {
                            Button(saveLabel) {
                                onSave()
                            }
                            Button(cancelLabel) {
                                onCancel()
                            }
                            .foregroundStyle(.secondary)
                        } else {
                            Button(editLabel) {
                                onEdit()
                            }
                        }
                    }
                }
                content
            }
        }
    }
}

private struct CardView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
    }
}

private struct TagRowView: View {
    let tags: [String]

    var body: some View {
        if tags.isEmpty {
            Text("—")
                .foregroundStyle(.secondary)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                        )
                }
            }
        }
    }
}

private struct LinkLabel: View {
    let title: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 6) {
                Image(systemName: "link")
                Text(title)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
            )
        }
    }
}

private struct InfoRow: Identifiable {
    let id = UUID()
    let label: String
    let value: String?
}

private struct InfoGridView: View {
    let rows: [InfoRow]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(row.value?.isEmpty == false ? row.value! : "—")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private extension CompanyDocument {
    var websiteURL: URL? {
        URL(string: website)
    }

    var linkedinURLValue: URL? {
        guard let linkedinURL, !linkedinURL.isEmpty else { return nil }
        return URL(string: linkedinURL)
    }
}

#Preview {
    NavigationStack {
        CompanyDetailView(company: AppState().companies[0])
            .environmentObject(AppState())
            .environmentObject(AppSettings())
    }
}

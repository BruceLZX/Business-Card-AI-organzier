import SwiftUI
import UIKit

struct ContactDetailView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @State private var draft: ContactDocument
    @State private var editingSection: Section?
    @State private var isPresentingCamera = false
    @State private var showEnrichConfirm = false

    private enum Section {
        case profile
        case details
        case links
        case tags
        case notes
        case company
    }

    init(contact: ContactDocument) {
        _draft = State(initialValue: contact)
    }

    private var company: CompanyDocument? {
        guard let companyID = draft.companyID else { return nil }
        return appState.company(for: companyID)
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

    private var shouldShowOriginalCompanyName: Bool {
        if let originalCompanyName = draft.originalCompanyName, !originalCompanyName.isEmpty {
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
                companySection
                photosSection
                notesSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(settings.text(.contact))
        .onAppear {
            if let current = appState.contact(for: draft.id) {
                draft = current
            }
        }
        .onReceive(appState.$contacts) { _ in
            if let current = appState.contact(for: draft.id) {
                draft = current
            }
        }
        .sheet(isPresented: $isPresentingCamera) {
            CameraView { image in
                if let photoID = appState.addContactPhoto(contactID: draft.id, image: image) {
                    draft.photoIDs.insert(photoID, at: 0)
                }
            }
        }
        .alert(settings.text(.enrichConfirmTitle), isPresented: $showEnrichConfirm) {
            Button(settings.text(.enrichButton)) {
                appState.enrichContact(contactID: draft.id)
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
                TextField(settings.text(.title), text: $draft.title)
                TextField(settings.text(.department), text: binding(for: $draft.department))
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
                    if !draft.title.isEmpty {
                        Text(draft.title)
                            .foregroundStyle(.secondary)
                    }
                    if let department = draft.department, !department.isEmpty {
                        Text(department)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        SectionCard(
            title: settings.text(.contactDetails),
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
                TextField(settings.text(.phone), text: $draft.phone)
                TextField(settings.text(.email), text: $draft.email)
                TextField(settings.text(.location), text: binding(for: $draft.location))
            } else {
                InfoGridView(rows: [
                    InfoRow(label: settings.text(.phone), value: draft.phone),
                    InfoRow(label: settings.text(.email), value: draft.email),
                    InfoRow(label: settings.text(.location), value: draft.location)
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
                TextField(settings.text(.personalSite), text: binding(for: $draft.website))
                TextField(settings.text(.linkedin), text: binding(for: $draft.linkedinURL))
            } else {
                HStack(spacing: 12) {
                    if let url = draft.websiteURL {
                        LinkLabel(title: settings.text(.personalSite), url: url)
                    }
                    if let url = draft.linkedinURLValue {
                        LinkLabel(title: settings.text(.linkedin), url: url)
                    }
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

    private var companySection: some View {
        SectionCard(
            title: settings.text(.relatedCompany),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: editingSection == .company,
            showsEdit: true,
            onEdit: { editingSection = .company },
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            if editingSection == .company {
                TextField(settings.text(.companyName), text: $draft.companyName)
                if shouldShowOriginalCompanyName {
                    TextField(settings.text(.originalCompanyName), text: binding(for: $draft.originalCompanyName))
                }
            } else if let company {
                NavigationLink {
                    CompanyDetailView(company: company)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(company.name)
                                .font(.headline)
                            if shouldShowOriginalCompanyName,
                               let originalCompanyName = draft.originalCompanyName,
                               !originalCompanyName.isEmpty,
                               originalCompanyName != company.name {
                                Text("\(settings.text(.originalCompanyName)): \(originalCompanyName)")
                                    .foregroundStyle(.secondary)
                            } else if let industry = company.industry, !industry.isEmpty {
                                Text(industry)
                                    .foregroundStyle(.secondary)
                            }
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
            } else if !draft.companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(draft.companyName)
                        .font(.headline)
                    if shouldShowOriginalCompanyName,
                       let originalCompanyName = draft.originalCompanyName,
                       !originalCompanyName.isEmpty,
                       originalCompanyName != draft.companyName {
                        Text("\(settings.text(.originalCompanyName)): \(originalCompanyName)")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(settings.text(.noCompanies))
                    .foregroundStyle(.secondary)
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
                            if let image = appState.loadContactPhoto(contactID: draft.id, photoID: photoID) {
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
        if editingSection == .company {
            let company = appState.ensureCompany(named: draft.companyName)
            draft.companyID = company?.id
            if let resolvedCompanyName = company?.name, !resolvedCompanyName.isEmpty {
                draft.companyName = resolvedCompanyName
            }
            if var company, let originalCompanyName = draft.originalCompanyName, !originalCompanyName.isEmpty {
                if company.originalName == nil || company.originalName?.isEmpty == true {
                    company.originalName = originalCompanyName
                    company.sourceLanguageCode = draft.sourceLanguageCode
                    appState.updateCompany(company)
                }
            }
            if let companyID = company?.id {
                appState.linkContact(draft.id, to: companyID)
            }
        }
        appState.updateContact(draft)
        editingSection = nil
    }

    private func cancelSection() {
        if let current = appState.contact(for: draft.id) {
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

private extension ContactDocument {
    var websiteURL: URL? {
        guard let website, !website.isEmpty else { return nil }
        return URL(string: website)
    }

    var linkedinURLValue: URL? {
        guard let linkedinURL, !linkedinURL.isEmpty else { return nil }
        return URL(string: linkedinURL)
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(contact: AppState().contacts[0])
            .environmentObject(AppState())
            .environmentObject(AppSettings())
    }
}

import SwiftUI
import UIKit

struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @State private var draft: ContactDocument
    @State private var editingSection: Section?
    @State private var isPresentingCamera = false
    @State private var showPhotoSourceSheet = false
    @State private var showPhotoPicker = false
    @State private var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showEnrichConfirm = false
    @State private var showLinkCompanyPicker = false
    @State private var showOriginalName = false
    @State private var showDeleteConfirm = false
    @State private var pendingUnlinkCompanyID: UUID?
    @State private var showUnlinkConfirm = false
    @State private var showEnrichError = false
    @State private var enrichErrorMessage = ""

    private enum Section {
        case profile
        case details
        case links
        case tags
        case notes
    }

    init(contact: ContactDocument) {
        _draft = State(initialValue: contact)
    }

    private var shouldShowOriginalName: Bool {
        if let originalName = draft.originalName, !originalName.isEmpty {
            return true
        }
        guard let sourceLanguageCode = draft.sourceLanguageCode else { return false }
        return sourceLanguageCode != settings.language.languageCode
    }

    private var displayName: String {
        if showOriginalName, let originalName = draft.originalName, !originalName.isEmpty {
            return originalName
        }
        return draft.name
    }

    private var displayLocation: String {
        if showOriginalName, let original = draft.originalLocation, !original.isEmpty {
            return original
        }
        return draft.location ?? ""
    }

    private var locationBinding: Binding<String> {
        Binding(
            get: {
                if showOriginalName {
                    return draft.originalLocation ?? ""
                }
                return draft.location ?? ""
            },
            set: { newValue in
                if showOriginalName {
                    draft.originalLocation = newValue
                } else {
                    draft.location = newValue
                }
            }
        )
    }

    private var isEnriching: Bool {
        appState.isEnrichingGlobal
    }

    private var linkedCompanies: [CompanyDocument] {
        var ids: [UUID] = []
        if let primary = draft.companyID {
            ids.append(primary)
        }
        ids.append(contentsOf: draft.additionalCompanyIDs.filter { $0 != draft.companyID })
        return ids.compactMap { appState.company(for: $0) }
    }

    private var aiSummaryText: String {
        if showOriginalName {
            return !draft.aiSummaryZH.isEmpty ? draft.aiSummaryZH : draft.aiSummaryEN
        }
        return !draft.aiSummaryEN.isEmpty ? draft.aiSummaryEN : draft.aiSummaryZH
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                languageToggle
                enrichmentControl

                profileSection
                aiSummarySection
                detailsSection
                linksSection
                tagsSection
                companySection
                photosSection
                notesSection
                deleteSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(settings.text(.contact))
        .navigationBarBackButtonHidden(isEnriching)
        .onAppear {
            if let current = appState.contact(for: draft.id) {
                draft = current
            }
            showOriginalName = settings.language == .chinese
        }
        .onReceive(appState.$contacts) { _ in
            if let current = appState.contact(for: draft.id) {
                draft = current
            }
        }
        .onDisappear {
            showOriginalName = settings.language == .chinese
        }
        .sheet(isPresented: $isPresentingCamera) {
            CameraView { image in
                if let photoID = appState.addContactPhoto(contactID: draft.id, image: image) {
                    draft.photoIDs.insert(photoID, at: 0)
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: photoSourceType) { image in
                if let photoID = appState.addContactPhoto(contactID: draft.id, image: image) {
                    draft.photoIDs.insert(photoID, at: 0)
                }
                showPhotoPicker = false
            } onCancel: {
                showPhotoPicker = false
            }
        }
        .confirmationDialog(
            settings.text(.addPhoto),
            isPresented: $showPhotoSourceSheet,
            titleVisibility: .visible
        ) {
            Button(settings.text(.addFromLibrary)) {
                photoSourceType = .photoLibrary
                showPhotoPicker = true
            }
            Button(settings.text(.takePhoto)) {
                isPresentingCamera = true
            }
            Button(settings.text(.cancel), role: .cancel) {}
        }
        .sheet(isPresented: $showLinkCompanyPicker) {
            NavigationStack {
                List {
                    ForEach(appState.companies.filter { company in
                        !linkedCompanies.contains(where: { $0.id == company.id })
                    }) { company in
                        Button {
                            linkCompany(company)
                            showLinkCompanyPicker = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayCompanyName(for: company))
                                if let industry = company.industry, !industry.isEmpty {
                                    Text(industry)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(settings.text(.companies))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(settings.text(.done)) {
                            showLinkCompanyPicker = false
                        }
                    }
                }
            }
        }
        .alert(settings.text(.enrichConfirmTitle), isPresented: $showEnrichConfirm) {
            Button(settings.text(.enrichButton)) {
                editingSection = nil
                appState.enrichContact(contactID: draft.id) { success, code in
                    DispatchQueue.main.async {
                        if !success {
                            enrichErrorMessage = {
                                switch code {
                                case "no_changes":
                                    return settings.text(.enrichNoChangesMessage)
                                case "missing_api_key":
                                    return settings.text(.enrichMissingKeyMessage)
                                default:
                                    return settings.text(.enrichFailedMessage)
                                }
                            }()
                            showEnrichError = true
                        }
                    }
                }
            }
            Button(settings.text(.cancel), role: .cancel) {}
        } message: {
            Text(settings.text(.enrichConfirmMessage))
        }
        .alert(settings.text(.enrichFailedTitle), isPresented: $showEnrichError) {
            Button(settings.text(.confirm)) {}
        } message: {
            Text(enrichErrorMessage)
        }
        .alert(settings.text(.unlinkConfirmTitle), isPresented: $showUnlinkConfirm) {
            Button(settings.text(.unlinkAction), role: .destructive) {
                if let companyID = pendingUnlinkCompanyID {
                    appState.unlinkContact(draft.id, from: companyID)
                    if let current = appState.contact(for: draft.id) {
                        draft = current
                    }
                }
                pendingUnlinkCompanyID = nil
            }
            Button(settings.text(.cancel), role: .cancel) {}
        } message: {
            Text(settings.text(.unlinkConfirmMessage))
        }
    }

    private var profileSection: some View {
        SectionCard(
            title: settings.text(.profile),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: editingSection == .profile,
            showsEdit: !isEnriching,
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
                    Text(displayName.isEmpty ? "—" : displayName)
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
                            .foregroundStyle(isFieldHighlighted("title") ? .blue : .secondary)
                        if let original = originalValue(for: "title"), !original.isEmpty {
                            Text("\(settings.text(.originalValue)): \(original)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let label = undoLabel(for: "title") {
                            UndoButton(label: label) {
                                undoField("title")
                            }
                        }
                    }
                    if let department = draft.department, !department.isEmpty {
                        Text(department)
                            .foregroundStyle(isFieldHighlighted("department") ? .blue : .secondary)
                        if let original = originalValue(for: "department"), !original.isEmpty {
                            Text("\(settings.text(.originalValue)): \(original)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let label = undoLabel(for: "department") {
                            UndoButton(label: label) {
                                undoField("department")
                            }
                        }
                    }
                    if !linkedCompanies.isEmpty {
                        Text(linkedCompanies.map { displayCompanyName(for: $0) }.joined(separator: " · "))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var aiSummarySection: some View {
        SectionCard(
            title: settings.text(.aiSummaryTitle),
            editLabel: settings.text(.edit),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: false,
            showsEdit: false,
            onEdit: {},
            onSave: {},
            onCancel: {}
        ) {
            if aiSummaryText.isEmpty {
                let message = draft.enrichedAt == nil
                ? settings.text(.aiSummaryPlaceholder)
                : settings.text(.aiSummaryEmpty)
                Text(message)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    if aiSummaryText.contains("可能不准确") {
                        UncertainBadge()
                    }
                    Text(aiSummaryText)
                        .foregroundStyle(.secondary)
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
            showsEdit: !isEnriching,
            onEdit: { editingSection = .details },
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            if editingSection == .details {
                TextField(settings.text(.phone), text: $draft.phone)
                TextField(settings.text(.email), text: $draft.email)
                TextField(settings.text(.location), text: locationBinding)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if let phoneURL = phoneURL(from: draft.phone) {
                        ContactLinkRow(
                            title: settings.text(.phone),
                            displayText: draft.phone,
                            url: phoneURL,
                            isHighlighted: isFieldHighlighted("phone"),
                            undoLabel: undoLabel(for: "phone"),
                            originalValue: originalValue(for: "phone"),
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField("phone") }
                        )
                    } else {
                        InfoRowView(
                            label: settings.text(.phone),
                            value: draft.phone,
                            isHighlighted: isFieldHighlighted("phone"),
                            undoLabel: undoLabel(for: "phone"),
                            originalValue: originalValue(for: "phone"),
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField("phone") }
                        )
                    }
                    if let emailURL = emailURL(from: draft.email) {
                        ContactLinkRow(
                            title: settings.text(.email),
                            displayText: draft.email,
                            url: emailURL,
                            isHighlighted: isFieldHighlighted("email"),
                            undoLabel: undoLabel(for: "email"),
                            originalValue: originalValue(for: "email"),
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField("email") }
                        )
                    } else {
                        InfoRowView(
                            label: settings.text(.email),
                            value: draft.email,
                            isHighlighted: isFieldHighlighted("email"),
                            undoLabel: undoLabel(for: "email"),
                            originalValue: originalValue(for: "email"),
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField("email") }
                        )
                    }
                    InfoRowView(
                        label: settings.text(.location),
                        value: displayLocation,
                        isHighlighted: isFieldHighlighted("location"),
                        undoLabel: undoLabel(for: "location"),
                        originalValue: originalValue(for: "location"),
                        originalLabel: settings.text(.originalValue),
                        onUndo: { undoField("location") }
                    )
                }
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
            showsEdit: !isEnriching,
            onEdit: { editingSection = .links },
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            if editingSection == .links {
                TextField(settings.text(.personalSite), text: binding(for: $draft.website))
                TextField(settings.text(.linkedin), text: binding(for: $draft.linkedinURL))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if let url = draft.websiteURL {
                        LinkRow(
                            title: settings.text(.personalSite),
                            url: url,
                            isHighlighted: isFieldHighlighted("website"),
                            undoLabel: undoLabel(for: "website"),
                            originalValue: originalValue(for: "website"),
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField("website") }
                        )
                    } else if let website = draft.website, !website.isEmpty {
                        InfoRowView(
                            label: settings.text(.personalSite),
                            value: website,
                            isHighlighted: isFieldHighlighted("website"),
                            undoLabel: undoLabel(for: "website"),
                            originalValue: originalValue(for: "website"),
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField("website") }
                        )
                    }

                    if let url = draft.linkedinURLValue {
                        LinkRow(
                            title: settings.text(.linkedin),
                            url: url,
                            isHighlighted: isFieldHighlighted("linkedin"),
                            undoLabel: undoLabel(for: "linkedin"),
                            originalValue: originalValue(for: "linkedin"),
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField("linkedin") }
                        )
                    } else if let linkedin = draft.linkedinURL, !linkedin.isEmpty {
                        InfoRowView(
                            label: settings.text(.linkedin),
                            value: linkedin,
                            isHighlighted: isFieldHighlighted("linkedin"),
                            undoLabel: undoLabel(for: "linkedin"),
                            originalValue: originalValue(for: "linkedin"),
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField("linkedin") }
                        )
                    }

                    if draft.websiteURL == nil, draft.linkedinURLValue == nil, draft.website?.isEmpty != false, draft.linkedinURL?.isEmpty != false {
                        Text("—")
                            .foregroundStyle(.secondary)
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
            showsEdit: !isEnriching,
            onEdit: { editingSection = .tags },
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            if editingSection == .tags {
                TagPickerView(
                    availableTags: appState.tagPool,
                    selectedTags: $draft.tags,
                    placeholder: settings.text(.tags),
                    addLabel: settings.text(.addButton),
                    selectLabel: settings.text(.selectTags),
                    titleLabel: settings.text(.tags),
                    doneLabel: settings.text(.done)
                )
                .onChange(of: draft.tags) { _, newValue in
                    appState.registerTags(newValue)
                }
            } else {
                TagRowView(
                    tags: draft.tags,
                    isHighlighted: isFieldHighlighted("tags"),
                    undoLabel: undoLabel(for: "tags"),
                    originalValue: originalValue(for: "tags"),
                    originalLabel: settings.text(.originalValue),
                    onUndo: { undoField("tags") }
                )
            }
        }
    }

    private var companySection: some View {
        SectionCard(
            title: settings.text(.relatedCompanies),
            editLabel: settings.text(.linkExisting),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: false,
            showsEdit: false,
            onEdit: {},
            onSave: saveSection,
            onCancel: cancelSection
        ) {
            VStack(spacing: 10) {
                if linkedCompanies.isEmpty {
                    Text(settings.text(.noCompanies))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(linkedCompanies) { company in
                        NavigationLink {
                            CompanyDetailView(company: company)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(displayCompanyName(for: company))
                                        .font(.headline)
                                    if let industry = company.industry, !industry.isEmpty {
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
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                                guard !isEnriching else { return }
                                pendingUnlinkCompanyID = company.id
                                showUnlinkConfirm = true
                            }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                guard !isEnriching else { return }
                                pendingUnlinkCompanyID = company.id
                                showUnlinkConfirm = true
                            } label: {
                                Label(settings.text(.unlinkAction), systemImage: "link.badge.xmark")
                            }
                        }
                    }
                }

                Button(settings.text(.linkNewCompany)) {
                    showLinkCompanyPicker = true
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isEnriching)
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
                    guard draft.photoIDs.count < 10 else { return }
                    showPhotoSourceSheet = true
                } label: {
                    Label(settings.text(.addPhoto), systemImage: "camera")
                }
                .disabled(draft.photoIDs.count >= 10)
                .disabled(isEnriching)
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
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            appState.deleteContactPhoto(contactID: draft.id, photoID: photoID)
                                            draft.photoIDs.removeAll { $0 == photoID }
                                        } label: {
                                            Label(settings.text(.deleteDocument), systemImage: "trash")
                                        }
                                    }
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
            showsEdit: !isEnriching,
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

    private var deleteSection: some View {
        VStack {
            Button(settings.text(.deleteDocument), role: .destructive) {
                showDeleteConfirm = true
            }
            .frame(maxWidth: .infinity)
            .disabled(isEnriching)
        }
        .alert(settings.text(.deleteConfirmTitle), isPresented: $showDeleteConfirm) {
            Button(settings.text(.confirmDelete), role: .destructive) {
                appState.deleteContact(draft.id)
                dismiss()
            }
            Button(settings.text(.cancel), role: .cancel) {}
        } message: {
            Text(settings.text(.deleteConfirmMessage))
        }
    }

    private func saveSection() {
        appState.updateContact(draft)
        editingSection = nil
    }

    private func cancelSection() {
        if let current = appState.contact(for: draft.id) {
            draft = current
        }
        editingSection = nil
    }

    private func linkCompany(_ company: CompanyDocument) {
        appState.linkContact(draft.id, to: company.id)
    }

    private var languageToggle: some View {
        Picker("", selection: $showOriginalName) {
            Text("EN").tag(false)
            Text("中文").tag(true)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 140)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func displayCompanyName(for company: CompanyDocument) -> String {
        if showOriginalName, let original = company.originalName, !original.isEmpty {
            return original
        }
        return company.name
    }

    private var enrichmentControl: some View {
        Group {
            if isEnriching {
                let stageText = enrichmentStageText()
                VStack(alignment: .leading, spacing: 8) {
                    Text(stageText)
                        .font(.headline)
                        .foregroundStyle(.blue)
                    if let progress = appState.enrichmentProgress {
                        ProgressView(value: progress.progress)
                            .progressViewStyle(.linear)
                    } else {
                        ProgressView()
                            .progressViewStyle(.linear)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                )
            } else {
                Button {
                    showEnrichConfirm = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text(draft.enrichedAt == nil ? settings.text(.enrichButton) : settings.text(.enrichAgainButton))
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
                .disabled(!settings.enableEnrichment || isEnriching)
            }
        }
    }

    private func enrichmentStageText() -> String {
        guard let progress = appState.enrichmentProgress else {
            return settings.text(.enrichingTitle)
        }
        switch progress.stage {
        case .analyzing:
            return settings.text(.enrichStageAnalyzing)
        case .searching(let current, let total):
            return String(format: settings.text(.enrichStageSearching), current, total)
        case .merging:
            return settings.text(.enrichStageMerging)
        case .complete:
            return settings.text(.enrichStageComplete)
        }
    }

    private func isFieldHighlighted(_ key: String) -> Bool {
        draft.lastEnrichedFields.contains(key)
    }

    private func undoLabel(for key: String) -> String? {
        draft.lastEnrichedValues[key] == nil ? nil : settings.text(.undoReplace)
    }

    private func originalValue(for key: String) -> String? {
        draft.lastEnrichedValues[key]
    }

    private func undoField(_ key: String) {
        guard let previous = draft.lastEnrichedValues[key] else { return }
        switch key {
        case "title":
            draft.title = previous
        case "department":
            draft.department = previous
        case "location":
            draft.location = previous
        case "phone":
            draft.phone = previous
        case "email":
            draft.email = previous
        case "website":
            draft.website = previous
        case "linkedin":
            draft.linkedinURL = previous
        case "tags":
            let restored = previous.split(separator: "·").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            draft.tags = restored.filter { !$0.isEmpty }
        default:
            break
        }
        draft.lastEnrichedValues.removeValue(forKey: key)
        draft.lastEnrichedFields.removeAll { $0 == key }
        appState.updateContact(draft)
    }

    private func binding(for value: Binding<String?>) -> Binding<String> {
        Binding(
            get: { value.wrappedValue ?? "" },
            set: { value.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }

    private func phoneURL(from number: String) -> URL? {
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let allowed = trimmed.filter { "+0123456789".contains($0) }
        guard !allowed.isEmpty else { return nil }
        return URL(string: "tel://\(allowed)")
    }

    private func emailURL(from email: String) -> URL? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: "mailto:\(trimmed)")
    }
}

private struct ContactLinkRow: View {
    let title: String
    let displayText: String
    let url: URL
    let isHighlighted: Bool
    let undoLabel: String?
    let originalValue: String?
    let originalLabel: String
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Link(destination: url) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                        Text(displayText)
                            .font(.subheadline)
                            .lineLimit(nil)
                            .foregroundStyle(isHighlighted ? .blue : .primary)
                        if displayText.contains("可能不准确") {
                            UncertainBadge()
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            }
            if let originalValue, !originalValue.isEmpty {
                Text("\(originalLabel)：\(originalValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let undoLabel {
                UndoButton(label: undoLabel, action: onUndo)
            }
        }
    }
}

private struct InfoRowView: View {
    let label: String
    let value: String?
    let isHighlighted: Bool
    let undoLabel: String?
    let originalValue: String?
    let originalLabel: String
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value?.isEmpty == false ? value! : "—")
                .font(.subheadline)
                .foregroundStyle(isHighlighted ? .blue : .primary)
            if let value, value.contains("可能不准确") {
                UncertainBadge()
            }
            if let originalValue, !originalValue.isEmpty {
                Text("\(originalLabel)：\(originalValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let undoLabel {
                UndoButton(label: undoLabel, action: onUndo)
            }
        }
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
    let isHighlighted: Bool
    let undoLabel: String?
    let originalValue: String?
    let originalLabel: String
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if tags.isEmpty {
                Text("—")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .foregroundStyle(isHighlighted ? .blue : .primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemBackground))
                            )
                    }
                }
            }
            if let originalValue, !originalValue.isEmpty {
                Text("\(originalLabel)：\(originalValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let undoLabel {
                UndoButton(label: undoLabel, action: onUndo)
            }
        }
    }
}

private struct LinkRow: View {
    let title: String
    let url: URL
    let isHighlighted: Bool
    let undoLabel: String?
    let originalValue: String?
    let originalLabel: String
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Link(destination: url) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                        Text(url.absoluteString)
                            .font(.subheadline)
                            .lineLimit(nil)
                            .foregroundStyle(isHighlighted ? .blue : .primary)
                        if url.absoluteString.contains("可能不准确") {
                            UncertainBadge()
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            }
            if let originalValue, !originalValue.isEmpty {
                Text("\(originalLabel)：\(originalValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let undoLabel {
                UndoButton(label: undoLabel, action: onUndo)
            }
        }
    }
}

private struct UndoButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }
}

private struct UncertainBadge: View {
    var body: some View {
        Text("可能不准确")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.yellow.opacity(0.2))
            )
            .foregroundStyle(.orange)
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

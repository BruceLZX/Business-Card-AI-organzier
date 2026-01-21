import SwiftUI
import UIKit

struct CompanyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @State private var draft: CompanyDocument
    @State private var editingSection: Section?
    @State private var isPresentingCamera = false
    @State private var showPhotoSourceSheet = false
    @State private var showPhotoPicker = false
    @State private var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showEnrichConfirm = false
    @State private var showLinkContactPicker = false
    @State private var showOriginalName = false
    @State private var showDeleteConfirm = false
    @State private var pendingUnlinkContactID: UUID?
    @State private var showUnlinkConfirm = false
    @State private var isSelectingContacts = false
    @State private var selectedContactIDs: Set<UUID> = []
    @State private var showBatchUnlinkConfirm = false
    @State private var showEnrichError = false
    @State private var enrichErrorMessage = ""
    @State private var showPhotoViewer = false
    @State private var selectedPhotoIndex = 0

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

    private var shouldShowOriginalName: Bool {
        if let originalName = draft.originalName, !originalName.isEmpty {
            return true
        }
        guard let sourceLanguageCode = draft.sourceLanguageCode else { return false }
        return sourceLanguageCode != settings.language.languageCode
    }

    private var displayLanguage: AppLanguage {
        showOriginalName ? .chinese : .english
    }

    private var displayName: String {
        draft.localizedName(for: displayLanguage)
    }

    private var displayLocation: String {
        draft.localizedLocation(for: displayLanguage)
    }

    private var displaySummary: String {
        draft.localizedSummary(for: displayLanguage)
    }

    private var displayIndustry: String? {
        draft.localizedIndustry(for: displayLanguage)
    }

    private var displayServiceType: String {
        draft.localizedServiceType(for: displayLanguage)
    }

    private var displayMarketRegion: String {
        draft.localizedMarketRegion(for: displayLanguage)
    }

    private var displayCompanySize: String? {
        draft.localizedCompanySize(for: displayLanguage)
    }

    private var displayHeadquarters: String? {
        draft.localizedHeadquarters(for: displayLanguage)
    }

    private var displayTags: [String] {
        draft.localizedTags(for: displayLanguage)
    }

    private var locationBinding: Binding<String> {
        Binding(
            get: {
                if showOriginalName {
                    return draft.originalLocation ?? ""
                }
                return draft.location
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

    private func displayContactName(for contact: ContactDocument) -> String {
        contact.localizedName(for: displayLanguage)
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
                contactsSection
                photosSection
                notesSection
                deleteSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(settings.text(.company))
        .navigationBarBackButtonHidden(isEnriching)
        .onAppear {
            if let current = appState.company(for: draft.id) {
                draft = current
            }
            showOriginalName = settings.language == .chinese
            appState.ensureCompanyLocalization(companyID: draft.id, targetLanguage: settings.language)
        }
        .onReceive(appState.$companies) { _ in
            if let current = appState.company(for: draft.id) {
                draft = current
            }
            appState.ensureCompanyLocalization(companyID: draft.id, targetLanguage: settings.language)
        }
        .onChange(of: settings.language) { _, newValue in
            showOriginalName = newValue == .chinese
            appState.ensureCompanyLocalization(companyID: draft.id, targetLanguage: newValue)
        }
        .onChange(of: showOriginalName) { _, newValue in
            let language: AppLanguage = newValue ? .chinese : .english
            appState.ensureCompanyLocalization(companyID: draft.id, targetLanguage: language)
        }
        .onDisappear {
            showOriginalName = settings.language == .chinese
        }
        .sheet(isPresented: $isPresentingCamera) {
            CameraView { image in
                if let photoID = appState.addCompanyPhoto(companyID: draft.id, image: image) {
                    draft.photoIDs.insert(photoID, at: 0)
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: photoSourceType) { image in
                if let photoID = appState.addCompanyPhoto(companyID: draft.id, image: image) {
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
        .sheet(isPresented: $showLinkContactPicker) {
            NavigationStack {
                List {
                    ForEach(appState.contacts.filter { !draft.relatedContactIDs.contains($0.id) }) { contact in
                        Button {
                            linkContact(contact)
                            showLinkContactPicker = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayContactName(for: contact))
                                Text(contact.title)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle(settings.text(.contacts))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(settings.text(.done)) {
                            showLinkContactPicker = false
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            CompanyPhotoViewer(
                photoIDs: draft.photoIDs,
                selectedIndex: $selectedPhotoIndex
            ) { photoID in
                appState.loadCompanyPhoto(companyID: draft.id, photoID: photoID)
            }
        }
        .alert(settings.text(.enrichConfirmTitle), isPresented: $showEnrichConfirm) {
            Button(settings.text(.enrichButton)) {
                editingSection = nil
                appState.enrichCompany(companyID: draft.id, tagLanguage: settings.language) { success, code in
                    DispatchQueue.main.async {
                        if !success {
                            enrichErrorMessage = {
                                switch code {
                                case "no_changes":
                                    return settings.text(.enrichNoChangesMessage)
                                case "missing_api_key":
                                    return settings.text(.enrichMissingKeyMessage)
                                case "network_error":
                                    return settings.text(.enrichNetworkMessage)
                                case "parse_failed":
                                    return settings.text(.enrichParseMessage)
                                case "empty_result":
                                    return settings.text(.enrichEmptyResultMessage)
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
                if let contactID = pendingUnlinkContactID {
                    appState.unlinkContact(contactID, from: draft.id)
                    if let current = appState.company(for: draft.id) {
                        draft = current
                    }
                }
                pendingUnlinkContactID = nil
            }
            Button(settings.text(.cancel), role: .cancel) {}
        } message: {
            Text(settings.text(.unlinkConfirmMessage))
        }
        .alert(settings.text(.unlinkConfirmTitle), isPresented: $showBatchUnlinkConfirm) {
            Button(settings.text(.unlinkAction), role: .destructive) {
                let ids = selectedContactIDs
                ids.forEach { appState.unlinkContact($0, from: draft.id) }
                if let current = appState.company(for: draft.id) {
                    draft = current
                }
                selectedContactIDs.removeAll()
                isSelectingContacts = false
            }
            Button(settings.text(.cancel), role: .cancel) {
                selectedContactIDs.removeAll()
                isSelectingContacts = false
            }
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
                TextField(settings.text(.summary), text: $draft.summary, axis: .vertical)
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
                    if !displaySummary.isEmpty {
                        Text(displaySummary)
                            .foregroundStyle(.secondary)
                    }
                    if let industry = displayIndustry, !industry.isEmpty {
                        Text(industry)
                            .foregroundStyle(isFieldHighlighted("industry") ? .blue : .secondary)
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
            title: settings.text(.companyDetails),
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
                TextField(settings.text(.industry), text: binding(for: $draft.industry))
                TextField(settings.text(.companySize), text: binding(for: $draft.companySize))
                TextField(settings.text(.revenue), text: binding(for: $draft.revenue))
                TextField(settings.text(.foundedYear), text: binding(for: $draft.foundedYear))
                TextField(settings.text(.headquarters), text: binding(for: $draft.headquarters))
                TextField(settings.text(.serviceTypeLabel), text: $draft.serviceType)
                TextField(settings.text(.location), text: locationBinding)
                TextField(settings.text(.marketRegionLabel), text: $draft.marketRegion)
                Picker(settings.text(.targetAudience), selection: $draft.targetAudience) {
                    ForEach(TargetAudience.allCases) { option in
                        Text(option.label(language: settings.language)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                InfoGridView(
                    rows: [
                        InfoRow(key: "industry", label: settings.text(.industry), value: displayIndustry),
                        InfoRow(key: "companySize", label: settings.text(.companySize), value: displayCompanySize),
                        InfoRow(key: "revenue", label: settings.text(.revenue), value: draft.revenue),
                        InfoRow(key: "foundedYear", label: settings.text(.foundedYear), value: draft.foundedYear),
                        InfoRow(key: "headquarters", label: settings.text(.headquarters), value: displayHeadquarters),
                        InfoRow(key: nil, label: settings.text(.serviceTypeLabel), value: displayServiceType),
                        InfoRow(key: nil, label: settings.text(.location), value: displayLocation),
                        InfoRow(key: nil, label: settings.text(.marketRegionLabel), value: displayMarketRegion),
                        InfoRow(key: nil, label: settings.text(.targetAudience), value: draft.targetAudience.label(language: settings.language))
                    ],
                    isHighlighted: isFieldHighlighted,
                    undoLabel: { undoLabel(for: $0) },
                    originalValue: { originalValue(for: $0) },
                    originalLabel: settings.text(.originalValue),
                    onUndo: { undoField($0) }
                )
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
                TextField(settings.text(.website), text: $draft.website)
                TextField(settings.text(.linkedin), text: binding(for: $draft.linkedinURL))
                TextField(settings.text(.phone), text: $draft.phone)
                TextField(settings.text(.address), text: $draft.address)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if let url = draft.websiteURL {
                        LinkRow(
                            title: settings.text(.website),
                            url: url,
                            isHighlighted: isFieldHighlighted("website"),
                            undoLabel: undoLabel(for: "website"),
                            originalValue: originalValue(for: "website"),
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField("website") }
                        )
                    } else if !draft.website.isEmpty {
                        InfoGridView(
                            rows: [
                                InfoRow(key: "website", label: settings.text(.website), value: draft.website)
                            ],
                            isHighlighted: isFieldHighlighted,
                            undoLabel: { undoLabel(for: $0) },
                            originalValue: { originalValue(for: $0) },
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField($0) }
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
                        InfoGridView(
                            rows: [
                                InfoRow(key: "linkedin", label: settings.text(.linkedin), value: linkedin)
                            ],
                            isHighlighted: isFieldHighlighted,
                            undoLabel: { undoLabel(for: $0) },
                            originalValue: { originalValue(for: $0) },
                            originalLabel: settings.text(.originalValue),
                            onUndo: { undoField($0) }
                        )
                    }
                    if draft.websiteURL == nil, draft.linkedinURLValue == nil, draft.website.isEmpty, draft.linkedinURL?.isEmpty != false {
                        Text("—")
                            .foregroundStyle(.secondary)
                    }
                    InfoGridView(
                        rows: [
                            InfoRow(key: "phone", label: settings.text(.phone), value: draft.phone),
                            InfoRow(key: "address", label: settings.text(.address), value: draft.address)
                        ],
                        isHighlighted: isFieldHighlighted,
                        undoLabel: { undoLabel(for: $0) },
                        originalValue: { originalValue(for: $0) },
                        originalLabel: settings.text(.originalValue),
                        onUndo: { undoField($0) }
                    )
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

    private var contactsSection: some View {
        SectionCard(
            title: settings.text(.relatedContacts),
            editLabel: settings.text(.linkExisting),
            saveLabel: settings.text(.save),
            cancelLabel: settings.text(.cancel),
            isEditing: false,
            showsEdit: false,
            onEdit: {},
            onSave: {},
            onCancel: {}
        ) {
            VStack(spacing: 10) {
                if relatedContacts.isEmpty {
                    Text(settings.text(.noRelatedContacts))
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 10) {
                            ForEach(relatedContacts) { contact in
                                if isSelectingContacts {
                                    Button {
                                        toggleSelection(contactID: contact.id)
                                    } label: {
                                        contactRow(
                                            contact,
                                            showsChevron: false,
                                            showsSelection: true,
                                            isSelected: selectedContactIDs.contains(contact.id)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink {
                                        ContactDetailView(contact: contact)
                                    } label: {
                                        contactRow(
                                            contact,
                                            showsChevron: true,
                                            showsSelection: false,
                                            isSelected: false
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Rectangle())
                                    .highPriorityGesture(
                                        LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                                            guard !isEnriching else { return }
                                            pendingUnlinkContactID = contact.id
                                            showUnlinkConfirm = true
                                        }
                                    )
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            guard !isEnriching else { return }
                                            pendingUnlinkContactID = contact.id
                                            showUnlinkConfirm = true
                                        } label: {
                                            Label(settings.text(.unlinkAction), systemImage: "link.badge.xmark")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(height: 240)
                }

                HStack(spacing: 10) {
                    if isSelectingContacts {
                        ActionCardButton(
                            title: settings.text(.cancel),
                            systemImage: "xmark",
                            role: nil
                        ) {
                            selectedContactIDs.removeAll()
                            isSelectingContacts = false
                        }
                    } else {
                        ActionCardButton(
                            title: settings.text(.linkNewContact),
                            systemImage: "plus"
                        ) {
                            showLinkContactPicker = true
                        }
                    }

                    ActionCardButton(
                        title: settings.text(.unlinkAction),
                        systemImage: "link.badge.xmark",
                        role: .destructive
                    ) {
                        if isSelectingContacts {
                            if !selectedContactIDs.isEmpty {
                                showBatchUnlinkConfirm = true
                            }
                        } else {
                            isSelectingContacts = true
                        }
                    }
                    .disabled(isEnriching || (isSelectingContacts && selectedContactIDs.isEmpty))
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
                    guard draft.photoIDs.count < 20 else { return }
                    showPhotoSourceSheet = true
                } label: {
                    Label(settings.text(.addPhoto), systemImage: "camera")
                }
                .disabled(draft.photoIDs.count >= 20)
                .disabled(isEnriching)
            }

            if draft.photoIDs.isEmpty {
                Text(settings.text(.noPhotos))
                    .foregroundStyle(.secondary)
            } else {
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(draft.photoIDs.enumerated()), id: \.element) { index, photoID in
                            if let image = appState.loadCompanyPhoto(companyID: draft.id, photoID: photoID) {
                                Button {
                                    selectedPhotoIndex = index
                                    showPhotoViewer = true
                                } label: {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        appState.deleteCompanyPhoto(companyID: draft.id, photoID: photoID)
                                        draft.photoIDs.removeAll { $0 == photoID }
                                    } label: {
                                        Label(settings.text(.deleteDocument), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 260)
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
                appState.deleteCompany(draft.id)
                dismiss()
            }
            Button(settings.text(.cancel), role: .cancel) {}
        } message: {
            Text(settings.text(.deleteConfirmMessage))
        }
    }

    private func saveSection() {
        appState.updateCompany(draft)
        appState.ensureCompanyLocalization(companyID: draft.id, targetLanguage: settings.language)
        editingSection = nil
    }

    private func cancelSection() {
        if let current = appState.company(for: draft.id) {
            draft = current
        }
        editingSection = nil
    }

    private func linkContact(_ contact: ContactDocument) {
        appState.linkContact(contact.id, to: draft.id)
    }

    private func toggleSelection(contactID: UUID) {
        if selectedContactIDs.contains(contactID) {
            selectedContactIDs.remove(contactID)
        } else {
            selectedContactIDs.insert(contactID)
        }
    }

    @ViewBuilder
    private func contactRow(
        _ contact: ContactDocument,
        showsChevron: Bool,
        showsSelection: Bool,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayContactName(for: contact))
                    .font(.headline)
                Text(contact.localizedTitle(for: displayLanguage))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showsSelection {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
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

    private func binding(for value: Binding<String?>) -> Binding<String> {
        Binding(
            get: { value.wrappedValue ?? "" },
            set: { value.wrappedValue = $0.isEmpty ? nil : $0 }
        )
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
        case "website":
            draft.website = previous
        case "linkedin":
            draft.linkedinURL = previous
        case "phone":
            draft.phone = previous
        case "address":
            draft.address = previous
        case "industry":
            draft.industry = previous
        case "companySize":
            draft.companySize = previous
        case "revenue":
            draft.revenue = previous
        case "foundedYear":
            draft.foundedYear = previous
        case "headquarters":
            draft.headquarters = previous
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
        appState.updateCompany(draft)
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

private struct ActionCardButton: View {
    let title: String
    let systemImage: String
    let role: ButtonRole?
    let action: () -> Void

    init(title: String, systemImage: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? .red : .primary)
    }
}

private struct CompanyPhotoViewer: View {
    let photoIDs: [UUID]
    @Binding var selectedIndex: Int
    let loadImage: (UUID) -> UIImage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: $selectedIndex) {
                ForEach(Array(photoIDs.enumerated()), id: \.element) { index, photoID in
                    if let image = loadImage(photoID) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(16)
            }
        }
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
    let key: String?
    let label: String
    let value: String?
}

private struct InfoGridView: View {
    let rows: [InfoRow]
    let isHighlighted: (String) -> Bool
    let undoLabel: (String) -> String?
    let originalValue: (String) -> String?
    let originalLabel: String
    let onUndo: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(row.value?.isEmpty == false ? row.value! : "—")
                        .font(.subheadline)
                        .foregroundStyle(
                            row.key.flatMap { isHighlighted($0) } == true ? .blue : .primary
                        )
                    if let value = row.value, value.contains("可能不准确") {
                        UncertainBadge()
                    }
                    if let key = row.key,
                       let original = originalValue(key),
                       !original.isEmpty {
                        Text("\(originalLabel)：\(original)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let key = row.key, let label = undoLabel(key) {
                        UndoButton(label: label) {
                            onUndo(key)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private extension CompanyDocument {
    var websiteURL: URL? {
        normalizedURL(from: website)
    }

    var linkedinURLValue: URL? {
        guard let linkedinURL, !linkedinURL.isEmpty else { return nil }
        return normalizedURL(from: linkedinURL)
    }

    private func normalizedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }
}

#Preview {
    NavigationStack {
        CompanyDetailView(company: AppState().companies[0])
            .environmentObject(AppState())
            .environmentObject(AppSettings())
    }
}

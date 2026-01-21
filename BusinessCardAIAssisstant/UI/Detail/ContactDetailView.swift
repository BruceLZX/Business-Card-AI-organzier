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
    @State private var isSelectingCompanies = false
    @State private var selectedCompanyIDs: Set<UUID> = []
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

    private var displayLanguage: AppLanguage {
        showOriginalName ? .chinese : .english
    }

    private var displayName: String {
        draft.localizedName(for: displayLanguage)
    }

    private var displayLocation: String {
        draft.localizedLocation(for: displayLanguage) ?? ""
    }

    private var displayTitle: String {
        draft.localizedTitle(for: displayLanguage)
    }

    private var displayDepartment: String? {
        draft.localizedDepartment(for: displayLanguage)
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
            appState.ensureContactLocalization(contactID: draft.id, targetLanguage: settings.language)
        }
        .onReceive(appState.$contacts) { _ in
            if let current = appState.contact(for: draft.id) {
                draft = current
            }
            appState.ensureContactLocalization(contactID: draft.id, targetLanguage: settings.language)
        }
        .onChange(of: settings.language) { _, newValue in
            showOriginalName = newValue == .chinese
            appState.ensureContactLocalization(contactID: draft.id, targetLanguage: newValue)
        }
        .onChange(of: showOriginalName) { _, newValue in
            let language: AppLanguage = newValue ? .chinese : .english
            appState.ensureContactLocalization(contactID: draft.id, targetLanguage: language)
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
        .fullScreenCover(isPresented: $showPhotoViewer) {
            ContactPhotoViewer(
                photoIDs: draft.photoIDs,
                selectedIndex: $selectedPhotoIndex
            ) { photoID in
                appState.loadContactPhoto(contactID: draft.id, photoID: photoID)
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
                appState.enrichContact(contactID: draft.id, tagLanguage: settings.language) { success, code in
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
        .alert(settings.text(.unlinkConfirmTitle), isPresented: $showBatchUnlinkConfirm) {
            Button(settings.text(.unlinkAction), role: .destructive) {
                let ids = selectedCompanyIDs
                ids.forEach { appState.unlinkContact(draft.id, from: $0) }
                if let current = appState.contact(for: draft.id) {
                    draft = current
                }
                selectedCompanyIDs.removeAll()
                isSelectingCompanies = false
            }
            Button(settings.text(.cancel), role: .cancel) {
                selectedCompanyIDs.removeAll()
                isSelectingCompanies = false
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
                    if !displayTitle.isEmpty {
                        Text(displayTitle)
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
                    if let department = displayDepartment, !department.isEmpty {
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
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 10) {
                            ForEach(linkedCompanies) { company in
                                if isSelectingCompanies {
                                    Button {
                                        toggleSelection(companyID: company.id)
                                    } label: {
                                        companyRow(
                                            company,
                                            showsChevron: false,
                                            showsSelection: true,
                                            isSelected: selectedCompanyIDs.contains(company.id)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink {
                                        CompanyDetailView(company: company)
                                    } label: {
                                        companyRow(
                                            company,
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
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(height: 240)
                }
                HStack(spacing: 10) {
                    if isSelectingCompanies {
                        ActionCardButton(
                            title: settings.text(.cancel),
                            systemImage: "xmark"
                        ) {
                            selectedCompanyIDs.removeAll()
                            isSelectingCompanies = false
                        }
                    } else {
                        ActionCardButton(
                            title: settings.text(.linkNewCompany),
                            systemImage: "plus"
                        ) {
                            showLinkCompanyPicker = true
                        }
                    }

                    ActionCardButton(
                        title: settings.text(.unlinkAction),
                        systemImage: "link.badge.xmark",
                        role: .destructive
                    ) {
                        if isSelectingCompanies {
                            if !selectedCompanyIDs.isEmpty {
                                showBatchUnlinkConfirm = true
                            }
                        } else {
                            isSelectingCompanies = true
                        }
                    }
                    .disabled(isEnriching || (isSelectingCompanies && selectedCompanyIDs.isEmpty))
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
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(draft.photoIDs.enumerated()), id: \.element) { index, photoID in
                            if let image = appState.loadContactPhoto(contactID: draft.id, photoID: photoID) {
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
                                        appState.deleteContactPhoto(contactID: draft.id, photoID: photoID)
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
        appState.ensureContactLocalization(contactID: draft.id, targetLanguage: settings.language)
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

    private func toggleSelection(companyID: UUID) {
        if selectedCompanyIDs.contains(companyID) {
            selectedCompanyIDs.remove(companyID)
        } else {
            selectedCompanyIDs.insert(companyID)
        }
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
        company.localizedName(for: displayLanguage)
    }

    @ViewBuilder
    private func companyRow(
        _ company: CompanyDocument,
        showsChevron: Bool,
        showsSelection: Bool,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayCompanyName(for: company))
                    .font(.headline)
                if let industry = company.localizedIndustry(for: displayLanguage), !industry.isEmpty {
                    Text(industry)
                        .foregroundStyle(.secondary)
                }
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

private struct ContactPhotoViewer: View {
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
        return normalizedURL(from: website)
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
        ContactDetailView(contact: AppState().contacts[0])
            .environmentObject(AppState())
            .environmentObject(AppSettings())
    }
}

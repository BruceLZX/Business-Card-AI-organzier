import SwiftUI
import UIKit
import PhotosUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @State private var isPresentingCreate = false
    @State private var isProcessingOCR = false
    @State private var capturedImages: [UIImage] = []
    @State private var ocrText: String = ""
    @State private var classificationType: CreateDocumentView.DocumentType = .company
    @State private var navigationTarget: CreateDocumentView.CreatedDocument?
    @State private var prefill: CreateDocumentView.Prefill?
    @State private var parseErrorMessage = ""
    @State private var showParseError = false
    @State private var showManualContact = false
    @State private var showManualCompany = false
    @State private var pendingDeleteRecent: RecentDocument?
    @State private var showRecentDeleteConfirm = false
    @State private var showAddFlow = false

    private let ocrService = OCRService()
    private let extractor = OCRExtractionService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(settings.text(.captureTitle))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                    Text(settings.text(.captureSubtitle))
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }

                Button {
                    showAddFlow = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        settings.accentColor.opacity(0.15),
                                        Color(.secondarySystemBackground)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 26)
                                    .stroke(settings.accentColor.opacity(0.2), lineWidth: 1)
                            )

                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(settings.accentColor)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: settings.accentColor.opacity(0.35), radius: 14, x: 0, y: 8)

                                if isProcessingOCR {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.2)
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 44, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }

                            Text(settings.text(.addButton))
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                }
                .buttonStyle(.plain)
                .disabled(isProcessingOCR)

                HStack(spacing: 12) {
                    Button {
                        showManualContact = true
                    } label: {
                        Text(settings.text(.contact))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showManualCompany = true
                    } label: {
                        Text(settings.text(.company))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(settings.text(.recentDocuments))
                        .font(.headline)

                    if appState.recentDocuments(for: settings.language).isEmpty {
                        Text(settings.text(.noRecentDocuments))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(appState.recentDocuments(for: settings.language)) { item in
                                NavigationLink {
                                    destinationView(for: item)
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(item.title)
                                                .font(.headline)
                                            Text(item.subtitle.isEmpty ? "—" : item.subtitle)
                                                .foregroundStyle(.secondary)
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        Text(item.kind == .company ? settings.text(.company) : settings.text(.contact))
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color(.secondarySystemBackground))
                                            )
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                                .onLongPressGesture {
                                    pendingDeleteRecent = item
                                    showRecentDeleteConfirm = true
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [
                    settings.accentColor.opacity(0.10),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            appState.companies.forEach { company in
                appState.ensureCompanyLocalization(companyID: company.id, targetLanguage: settings.language)
            }
            appState.contacts.forEach { contact in
                appState.ensureContactLocalization(contactID: contact.id, targetLanguage: settings.language)
            }
        }
        .onChange(of: settings.language) { _, _ in
            appState.companies.forEach { company in
                appState.ensureCompanyLocalization(companyID: company.id, targetLanguage: settings.language)
            }
            appState.contacts.forEach { contact in
                appState.ensureContactLocalization(contactID: contact.id, targetLanguage: settings.language)
            }
        }
        .sheet(isPresented: $showAddFlow) {
            AddCaptureView(
                title: settings.text(.captureTitle),
                subtitle: settings.text(.captureSubtitle),
                cameraLabel: settings.text(.takePhoto),
                libraryLabel: settings.text(.addFromLibrary),
                cancelLabel: settings.text(.cancel),
                confirmLabel: settings.text(.create),
                maxPhotos: 10
            ) { images in
                showAddFlow = false
                handleCapture(images)
            }
            .environmentObject(settings)
        }
        .sheet(isPresented: $isPresentingCreate) {
            CreateDocumentView(
                images: capturedImages,
                ocrText: ocrText,
                initialType: classificationType,
                source: .scan,
                prefill: prefill
            ) { created in
                navigationTarget = created
            }
                .environmentObject(appState)
                .environmentObject(settings)
        }
        .sheet(isPresented: $showManualContact) {
            CreateDocumentView(
                images: [],
                ocrText: "",
                initialType: .contact,
                source: .manual,
                prefill: nil
            ) { created in
                navigationTarget = created
            }
            .environmentObject(appState)
            .environmentObject(settings)
        }
        .sheet(isPresented: $showManualCompany) {
            CreateDocumentView(
                images: [],
                ocrText: "",
                initialType: .company,
                source: .manual,
                prefill: nil
            ) { created in
                navigationTarget = created
            }
            .environmentObject(appState)
            .environmentObject(settings)
        }
        .navigationDestination(item: $navigationTarget) { target in
            switch target.kind {
            case .company:
                if let company = appState.company(for: target.id) {
                    CompanyDetailView(company: company)
                } else {
                    Text(settings.text(.noCompanies))
                }
            case .contact:
                if let contact = appState.contact(for: target.id) {
                    ContactDetailView(contact: contact)
                } else {
                    Text(settings.text(.noContacts))
                }
            }
        }
        .alert(settings.text(.parseErrorTitle), isPresented: $showParseError) {
            Button(settings.text(.done), role: .cancel) {}
        } message: {
            Text(parseErrorMessage)
        }
        .confirmationDialog(settings.text(.deleteConfirmTitle), isPresented: $showRecentDeleteConfirm) {
            Button(settings.text(.confirmDelete), role: .destructive) {
                if let item = pendingDeleteRecent {
                    deleteRecent(item)
                }
                pendingDeleteRecent = nil
            }
            Button(settings.text(.cancel), role: .cancel) {
                pendingDeleteRecent = nil
            }
        } message: {
            Text(settings.text(.deleteConfirmMessage))
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func handleCapture(_ images: [UIImage]) {
        capturedImages = images
        isProcessingOCR = true
        ocrText = ""
        extractor.parse(images: images) { parsed in
            DispatchQueue.main.async {
                if let parsed {
                    if let error = parsed.error, !error.code.isEmpty {
                        parseErrorMessage = error.code == "multiple_entities"
                        ? settings.text(.multipleEntitiesMessage)
                        : (error.message.isEmpty ? settings.text(.parseFailedMessage) : error.message)
                        showParseError = true
                        isProcessingOCR = false
                        return
                    }
                    let builtPrefill = CreateDocumentView.Prefill.from(parsed)
                    classificationType = builtPrefill.type == .company ? .company : .contact
                    if builtPrefill.type == .both {
                        classificationType = .company
                    }
                    prefill = builtPrefill
                    isProcessingOCR = false
                    isPresentingCreate = true
                    images.forEach { appState.addCapture($0) }
                    return
                }

                // Vision parse failed, fallback to OCR text pipeline.
                recognizeAllText(in: images) { recognizedText in
                    DispatchQueue.main.async {
                        ocrText = recognizedText
                        extractor.parse(text: ocrText) { fallbackParsed in
                            DispatchQueue.main.async {
                                if let fallbackParsed {
                                    if let error = fallbackParsed.error, !error.code.isEmpty {
                                        parseErrorMessage = error.code == "multiple_entities"
                                        ? settings.text(.multipleEntitiesMessage)
                                        : (error.message.isEmpty ? settings.text(.parseFailedMessage) : error.message)
                                        showParseError = true
                                        isProcessingOCR = false
                                        return
                                    }
                                    let builtPrefill = CreateDocumentView.Prefill.from(fallbackParsed)
                                    classificationType = builtPrefill.type == .company ? .company : .contact
                                    if builtPrefill.type == .both {
                                        classificationType = .company
                                    }
                                    prefill = builtPrefill
                                    isProcessingOCR = false
                                    isPresentingCreate = true
                                    images.forEach { appState.addCapture($0) }
                                    return
                                }

                                parseErrorMessage = settings.text(.parseFailedMessage)
                                showParseError = true
                                isProcessingOCR = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func recognizeAllText(in images: [UIImage], completion: @escaping (String) -> Void) {
        guard !images.isEmpty else {
            completion("")
            return
        }

        var texts: [String] = Array(repeating: "", count: images.count)
        let group = DispatchGroup()

        for (index, image) in images.enumerated() {
            group.enter()
            ocrService.recognizeText(in: image) { result in
                texts[index] = result?.text ?? ""
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(texts.joined(separator: "\n"))
        }
    }

    @ViewBuilder
    private func destinationView(for item: RecentDocument) -> some View {
        switch item.kind {
        case .company:
            if let company = appState.company(for: item.id) {
                CompanyDetailView(company: company)
            } else {
                Text(settings.text(.noCompanies))
            }
        case .contact:
            if let contact = appState.contact(for: item.id) {
                ContactDetailView(contact: contact)
            } else {
                Text(settings.text(.noContacts))
            }
        }
    }

    private func deleteRecent(_ item: RecentDocument) {
        switch item.kind {
        case .company:
            appState.deleteCompany(item.id)
        case .contact:
            appState.deleteContact(item.id)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppState())
            .environmentObject(AppSettings())
    }
}

private struct AddCaptureView: View {
    let title: String
    let subtitle: String
    let cameraLabel: String
    let libraryLabel: String
    let cancelLabel: String
    let confirmLabel: String
    let maxPhotos: Int
    let onConfirm: ([UIImage]) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var photos: [UIImage] = []
    @State private var showCamera = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showPhotoViewer = false
    @State private var selectedPhotoIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                photoPool

                HStack(spacing: 12) {
                    Button(action: { showCamera = true }) {
                        actionRow(systemImage: "camera.fill", title: cameraLabel)
                    }
                    .buttonStyle(.plain)
                    .disabled(photos.count >= maxPhotos)

                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: max(0, maxPhotos - photos.count),
                        matching: .images
                    ) {
                        actionRow(systemImage: "photo.on.rectangle", title: libraryLabel)
                    }
                    .buttonStyle(.plain)
                    .disabled(photos.count >= maxPhotos)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(cancelLabel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(confirmLabel) {
                        onConfirm(photos)
                    }
                    .disabled(photos.isEmpty)
                }
            }
            .fullScreenCover(isPresented: $showPhotoViewer) {
                AddCapturePhotoViewer(
                    photos: photos,
                    selectedIndex: $selectedPhotoIndex
                )
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    if photos.count < maxPhotos {
                        photos.append(image)
                    }
                    showCamera = false
                }
            }
            .onChange(of: selectedItems) { _, items in
                guard !items.isEmpty else { return }
                loadPickerItems(items)
            }
        }
    }

    private var photoPool: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(settings.text(.photos)) \(photos.count)/\(maxPhotos)")
                    .font(.headline)
                Spacer()
            }

            if photos.isEmpty {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 160)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text(settings.text(.addPhotosPrompt))
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                    )
            } else {
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Button {
                                    selectedPhotoIndex = index
                                    showPhotoViewer = true
                                } label: {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 140)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    photos.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(6)
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
    }

    private func actionRow(systemImage: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
            Text(title)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func loadPickerItems(_ items: [PhotosPickerItem]) {
        let remaining = max(0, maxPhotos - photos.count)
        let limited = Array(items.prefix(remaining))
        Task {
            for item in limited {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        if photos.count < maxPhotos {
                            photos.append(image)
                        }
                    }
                }
            }
            await MainActor.run {
                selectedItems = []
            }
        }
    }
}

private struct AddCapturePhotoViewer: View {
    let photos: [UIImage]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $selectedIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    Image(uiImage: photos[index])
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                        .background(Color.black)
                }
            }
            .tabViewStyle(.page)
            .background(Color.black.ignoresSafeArea())

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .padding()
            }
        }
        .ignoresSafeArea()
    }
}

private struct AddSourceSheet: View {
    let title: String
    let subtitle: String
    let cameraLabel: String
    let libraryLabel: String
    let cancelLabel: String
    let onCamera: () -> Void
    let onLibrary: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Button(action: onCamera) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text(cameraLabel)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)

            Button(action: onLibrary) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20, weight: .semibold))
                    Text(libraryLabel)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)

            Button(cancelLabel, role: .cancel, action: onCancel)
                .padding(.top, 4)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}

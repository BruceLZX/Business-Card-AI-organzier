import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @State private var isPresentingCamera = false
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

    private let ocrService = OCRService()
    private let classifier = DocumentClassifier()
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
                    isPresentingCamera = true
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
        .sheet(isPresented: $isPresentingCamera) {
            MultiCaptureView(maxPhotos: 5) { images in
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
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppState())
            .environmentObject(AppSettings())
    }
}

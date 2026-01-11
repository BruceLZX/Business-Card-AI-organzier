import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @State private var isPresentingCamera = false
    @State private var isPresentingCreate = false
    @State private var isProcessingOCR = false
    @State private var capturedImage: UIImage?
    @State private var ocrText: String = ""
    @State private var classificationType: CreateDocumentView.DocumentType = .company
    @State private var navigationTarget: CreateDocumentView.CreatedDocument?

    private let ocrService = OCRService()
    private let classifier = DocumentClassifier()

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

                VStack(alignment: .leading, spacing: 12) {
                    Text(settings.text(.recentDocuments))
                        .font(.headline)

                    if appState.recentDocuments.isEmpty {
                        Text(settings.text(.noRecentDocuments))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(appState.recentDocuments) { item in
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
        .sheet(isPresented: $isPresentingCamera) {
            CameraView { image in
                handleCapture(image)
            }
        }
        .sheet(isPresented: $isPresentingCreate) {
            CreateDocumentView(
                image: capturedImage,
                ocrText: ocrText,
                initialType: classificationType
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
        .toolbar(.hidden, for: .navigationBar)
    }

    private func handleCapture(_ image: UIImage) {
        capturedImage = image
        isProcessingOCR = true
        ocrService.recognizeText(in: image) { result in
            DispatchQueue.main.async {
                ocrText = result?.text ?? ""
                classifier.classify(text: ocrText) { type in
                    DispatchQueue.main.async {
                        isProcessingOCR = false
                        classificationType = (type == .contact) ? .contact : .company
                        isPresentingCreate = true
                        appState.addCapture(image)
                    }
                }
            }
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

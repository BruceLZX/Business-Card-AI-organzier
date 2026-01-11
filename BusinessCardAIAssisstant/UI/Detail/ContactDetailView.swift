import SwiftUI
import UIKit

struct ContactDetailView: View {
    @EnvironmentObject private var appState: AppState
    @State private var draft: ContactDocument
    @State private var isEditing = false
    @State private var isPresentingCamera = false

    init(contact: ContactDocument) {
        _draft = State(initialValue: contact)
    }

    private var company: CompanyDocument? {
        guard let companyID = draft.companyID else { return nil }
        return appState.company(for: companyID)
    }

    var body: some View {
        Form {
            Section("Contact") {
                if isEditing {
                    TextField("Name", text: $draft.name)
                    TextField("Title", text: $draft.title)
                    TextField("Phone", text: $draft.phone)
                    TextField("Email", text: $draft.email)
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                    TextField(
                        "Tags",
                        text: Binding(
                            get: { draft.tags.joined(separator: ", ") },
                            set: { draft.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                        )
                    )
                } else {
                    Text(draft.name)
                        .font(.headline)
                    Text(draft.title)
                        .foregroundStyle(.secondary)
                    Text(draft.phone)
                    Text(draft.email)
                    Text(draft.notes)
                        .foregroundStyle(.secondary)
                    if !draft.tags.isEmpty {
                        Text("Tags: \(draft.tags.joined(separator: ", "))")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Company") {
                if let company {
                    NavigationLink {
                        CompanyDetailView(company: company)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(company.name)
                            Text(company.serviceType)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("No linked company")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Photos") {
                Button {
                    isPresentingCamera = true
                } label: {
                    Label("Add Photo", systemImage: "camera")
                }

                if draft.photoIDs.isEmpty {
                    Text("No photos attached")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(draft.photoIDs, id: \.self) { photoID in
                                if let image = appState.loadContactPhoto(contactID: draft.id, photoID: photoID) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.gray.opacity(0.2))
                                        .frame(width: 120, height: 80)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Contact")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        appState.updateContact(draft)
                    }
                    isEditing.toggle()
                }
            }
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if let current = appState.contact(for: draft.id) {
                            draft = current
                        }
                        isEditing = false
                    }
                }
            }
        }
        .onAppear {
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
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(contact: AppState().contacts[0])
            .environmentObject(AppState())
    }
}

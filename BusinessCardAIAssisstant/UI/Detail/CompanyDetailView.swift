import SwiftUI

struct CompanyDetailView: View {
    @EnvironmentObject private var appState: AppState
    @State private var draft: CompanyDocument
    @State private var isEditing = false

    init(company: CompanyDocument) {
        _draft = State(initialValue: company)
    }

    private var relatedContacts: [ContactDocument] {
        appState.contacts.filter { draft.relatedContactIDs.contains($0.id) }
    }

    var body: some View {
        Form {
            Section("Company") {
                if isEditing {
                    TextField("Name", text: $draft.name)
                    TextField("Summary", text: $draft.summary, axis: .vertical)
                    TextField("Website", text: $draft.website)
                    TextField("Phone", text: $draft.phone)
                    TextField("Address", text: $draft.address)
                } else {
                    Text(draft.name)
                        .font(.headline)
                    Text(draft.summary)
                        .foregroundStyle(.secondary)
                    Text(draft.website)
                    Text(draft.phone)
                    Text(draft.address)
                }
            }

            Section("Business") {
                if isEditing {
                    TextField("Service type", text: $draft.serviceType)
                    TextField("Location", text: $draft.location)
                    TextField("Market region", text: $draft.marketRegion)
                    TextField(
                        "Service keywords",
                        text: Binding(
                            get: { draft.serviceKeywords.joined(separator: ", ") },
                            set: { draft.serviceKeywords = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                        )
                    )
                } else {
                    Text("Service type: \(draft.serviceType)")
                    Text("Location: \(draft.location)")
                    Text("Market region: \(draft.marketRegion)")
                    Text("Keywords: \(draft.serviceKeywords.joined(separator: ", "))")
                }
            }

            Section("Target Audience") {
                if isEditing {
                    Picker("Target audience", selection: $draft.targetAudience) {
                        ForEach(TargetAudience.allCases) { audience in
                            Text(audience.rawValue).tag(audience)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Text(draft.targetAudience.rawValue)
                }
            }

            Section("Related Contacts") {
                if relatedContacts.isEmpty {
                    Text("No related contacts")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(relatedContacts) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name)
                                Text(contact.title)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Photos") {
                if draft.photoIDs.isEmpty {
                    Text("No photos attached")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(draft.photoIDs, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.gray.opacity(0.2))
                                    .frame(width: 120, height: 80)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Company")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        appState.updateCompany(draft)
                    }
                    isEditing.toggle()
                }
            }
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if let current = appState.company(for: draft.id) {
                            draft = current
                        }
                        isEditing = false
                    }
                }
            }
        }
        .onAppear {
            if let current = appState.company(for: draft.id) {
                draft = current
            }
        }
    }
}

#Preview {
    NavigationStack {
        CompanyDetailView(company: AppState().companies[0])
            .environmentObject(AppState())
    }
}

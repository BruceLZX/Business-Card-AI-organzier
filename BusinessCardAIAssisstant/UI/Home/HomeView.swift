import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var isPresentingCamera = false
    @State private var recentCaptures: [UIImage] = []

    private var filteredCompanies: [CompanyDocument] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return appState.companies }
        return appState.companies.filter { $0.matchesSearch(trimmed) }
    }

    private var filteredContacts: [ContactDocument] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return appState.contacts }
        return appState.contacts.filter { $0.matchesSearch(trimmed) }
    }

    var body: some View {
        List {
            Section {
                Button {
                    isPresentingCamera = true
                } label: {
                    Label("Capture Card or Brochure", systemImage: "camera")
                }
            }

            if !recentCaptures.isEmpty {
                Section("Recent Captures") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recentCaptures.indices, id: \.self) { index in
                                Image(uiImage: recentCaptures[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Companies") {
                if filteredCompanies.isEmpty {
                    Text("No companies found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredCompanies) { company in
                        NavigationLink {
                            CompanyDetailView(company: company)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(company.name)
                                    .font(.headline)
                                Text(company.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Contacts") {
                if filteredContacts.isEmpty {
                    Text("No contacts found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredContacts) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name)
                                    .font(.headline)
                                Text("\(contact.title) · \(contact.companyName)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Home")
        .searchable(text: $searchText, prompt: "Search people, companies, keywords")
        .sheet(isPresented: $isPresentingCamera) {
            CameraView { image in
                recentCaptures.insert(image, at: 0)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppState())
    }
}

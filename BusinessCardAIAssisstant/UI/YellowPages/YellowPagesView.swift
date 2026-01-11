import SwiftUI

struct YellowPagesView: View {
    enum PageType: String, CaseIterable, Identifiable {
        case companies = "Companies"
        case contacts = "Contacts"

        var id: String { rawValue }
    }

    @EnvironmentObject private var appState: AppState
    @State private var pageType: PageType = .companies
    @State private var filters = FilterOptions()
    @State private var isPresentingFilters = false

    private var filteredCompanies: [CompanyDocument] {
        appState.companies.filter { $0.matches(filters: filters) }
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("View", selection: $pageType) {
                ForEach(PageType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                if pageType == .companies {
                    Section("Companies") {
                        if filteredCompanies.isEmpty {
                            Text("No companies match the filters")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(filteredCompanies) { company in
                                NavigationLink {
                                    CompanyDetailView(company: company)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(company.name)
                                            .font(.headline)
                                        Text(company.serviceType)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Section("Contacts") {
                        ForEach(appState.contacts) { contact in
                            NavigationLink {
                                ContactDetailView(contact: contact)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.name)
                                        .font(.headline)
                                    Text(contact.companyName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Yellow Pages")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingFilters = true
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                .disabled(pageType != .companies)
            }
        }
        .sheet(isPresented: $isPresentingFilters) {
            FilterSheetView(filters: $filters)
        }
    }
}

#Preview {
    NavigationStack {
        YellowPagesView()
            .environmentObject(AppState())
    }
}

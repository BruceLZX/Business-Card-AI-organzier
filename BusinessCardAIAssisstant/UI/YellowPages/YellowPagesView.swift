import SwiftUI

struct DirectoryView: View {
    enum PageType: String, CaseIterable, Identifiable {
        case companies = "Companies"
        case contacts = "Contacts"

        var id: String { rawValue }
    }

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @State private var pageType: PageType = .companies
    @State private var filters = FilterOptions()
    @State private var isPresentingFilters = false
    @State private var searchText = ""

    private var filteredCompanies: [CompanyDocument] {
        let searched = SearchService.filterCompanies(appState.companies, query: searchText)
        return searched.filter { $0.matches(filters: filters) }
    }

    private var filteredContacts: [ContactDocument] {
        SearchService.filterContacts(appState.contacts, query: searchText)
    }

    private var groupedCompanies: [(key: String, items: [CompanyDocument])] {
        groupItems(filteredCompanies) { $0.name }
    }

    private var groupedContacts: [(key: String, items: [ContactDocument])] {
        groupItems(filteredContacts) { $0.name }
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("View", selection: $pageType) {
                Text(settings.text(.companies)).tag(PageType.companies)
                Text(settings.text(.contacts)).tag(PageType.contacts)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12, pinnedViews: [.sectionHeaders]) {
                            if pageType == .companies {
                                if groupedCompanies.isEmpty {
                                    Text(settings.text(.noCompanies))
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 24)
                                } else {
                                    ForEach(groupedCompanies, id: \.key) { group in
                                        Section {
                                            ForEach(group.items) { company in
                                                NavigationLink {
                                                    CompanyDetailView(company: company)
                                                } label: {
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        Text(company.name)
                                                            .font(.headline)
                                                        Text(company.serviceType)
                                                            .font(.subheadline)
                                                            .foregroundStyle(.secondary)
                                                        if !company.tags.isEmpty {
                                                            Text(company.tags.joined(separator: " · "))
                                                                .font(.caption)
                                                                .foregroundStyle(.secondary)
                                                        }
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(16)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .fill(Color(.secondarySystemBackground))
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        } header: {
                                            sectionHeader(title: group.key)
                                                .id(sectionID(for: group.key, page: pageType))
                                        }
                                    }
                                }
                            } else {
                                if groupedContacts.isEmpty {
                                    Text(settings.text(.noContacts))
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 24)
                                } else {
                                    ForEach(groupedContacts, id: \.key) { group in
                                        Section {
                                            ForEach(group.items) { contact in
                                                NavigationLink {
                                                    ContactDetailView(contact: contact)
                                                } label: {
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        Text(contact.name)
                                                            .font(.headline)
                                                        Text("\(contact.title) · \(contact.companyName)")
                                                            .font(.subheadline)
                                                            .foregroundStyle(.secondary)
                                                        if !contact.tags.isEmpty {
                                                            Text(contact.tags.joined(separator: " · "))
                                                                .font(.caption)
                                                                .foregroundStyle(.secondary)
                                                        }
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(16)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .fill(Color(.secondarySystemBackground))
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        } header: {
                                            sectionHeader(title: group.key)
                                                .id(sectionID(for: group.key, page: pageType))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }

                    indexSidebar(proxy: proxy)
                        .padding(.trailing, 6)
                }
            }
        }
        .navigationTitle(settings.text(.directoryTitle))
        .searchable(text: $searchText, prompt: settings.text(.searchPrompt))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingFilters = true
                } label: {
                    Label(settings.text(.filters), systemImage: "line.3.horizontal.decrease.circle")
                }
                .disabled(pageType != .companies)
            }
        }
        .sheet(isPresented: $isPresentingFilters) {
            FilterSheetView(filters: $filters)
                .environmentObject(settings)
        }
    }

    private func groupItems<T>(_ items: [T], name: (T) -> String) -> [(key: String, items: [T])] {
        let grouped = Dictionary(grouping: items) { item -> String in
            initialLetter(from: name(item))
        }
        let sortedKeys = grouped.keys.sorted()
        return sortedKeys.map { key in
            let sortedItems = (grouped[key] ?? []).sorted { lhs, rhs in
                name(lhs).localizedCaseInsensitiveCompare(name(rhs)) == .orderedAscending
            }
            return (key, sortedItems)
        }
    }

    private func initialLetter(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "#" }
        let transformed = trimmed as NSString
        let mutable = NSMutableString(string: transformed)
        if CFStringTransform(mutable, nil, kCFStringTransformToLatin, false) {
            CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false)
        }
        let upper = (mutable as String).uppercased()
        guard let first = upper.first else { return "#" }
        if first >= "A" && first <= "Z" {
            return String(first)
        }
        return "#"
    }

    private func sectionID(for key: String, page: PageType) -> String {
        "\(page.rawValue)-\(key)"
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func indexSidebar(proxy: ScrollViewProxy) -> some View {
        let keys = pageType == .companies ? groupedCompanies.map(\.key) : groupedContacts.map(\.key)
        if !keys.isEmpty {
            VStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(sectionID(for: key, page: pageType), anchor: .top)
                        }
                    } label: {
                        Text(key)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

#Preview {
    NavigationStack {
        DirectoryView()
            .environmentObject(AppState())
            .environmentObject(AppSettings())
    }
}

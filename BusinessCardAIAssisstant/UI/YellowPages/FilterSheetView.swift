import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: FilterOptions

    var body: some View {
        NavigationStack {
            Form {
                Section("Company Location") {
                    TextField("City or region", text: $filters.location)
                }

                Section("Service Type") {
                    TextField("Service category", text: $filters.serviceType)
                }

                Section("Target Audience") {
                    Picker("Target Audience", selection: $filters.targetAudience) {
                        ForEach(TargetAudienceFilter.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Market Region") {
                    TextField("Market region", text: $filters.marketRegion)
                }

                if !filters.isEmpty {
                    Section {
                        Button("Reset Filters") {
                            filters = FilterOptions()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

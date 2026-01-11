import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Binding var filters: FilterOptions

    var body: some View {
        NavigationStack {
            Form {
                Section(settings.text(.companyLocation)) {
                    TextField(settings.text(.location), text: $filters.location)
                }

                Section(settings.text(.serviceType)) {
                    TextField(settings.text(.serviceTypeLabel), text: $filters.serviceType)
                }

                Section(settings.text(.tagFilter)) {
                    TextField(settings.text(.tagFilter), text: $filters.tag)
                }

                Section(settings.text(.targetAudience)) {
                    Picker(settings.text(.targetAudience), selection: $filters.targetAudience) {
                        ForEach(TargetAudienceFilter.allCases) { option in
                            Text(option.label(language: settings.language)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(settings.text(.marketRegion)) {
                    TextField(settings.text(.marketRegionLabel), text: $filters.marketRegion)
                }

                if !filters.isEmpty {
                    Section {
                        Button(settings.text(.resetFilters)) {
                            filters = FilterOptions()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(settings.text(.filterTitle))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(settings.text(.done)) {
                        dismiss()
                    }
                }
            }
        }
    }
}

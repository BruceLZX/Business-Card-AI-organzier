import Foundation

extension ContactDocument {
    func localizedName(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return localizedNameEN?.nonEmpty ?? name.nonEmpty ?? originalName?.nonEmpty ?? ""
        case .chinese:
            return localizedNameZH?.nonEmpty ?? originalName?.nonEmpty ?? name.nonEmpty ?? ""
        }
    }

    func localizedTitle(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return localizedTitleEN?.nonEmpty ?? title
        case .chinese:
            return localizedTitleZH?.nonEmpty ?? title
        }
    }

    func localizedDepartment(for language: AppLanguage) -> String? {
        switch language {
        case .english:
            return localizedDepartmentEN?.nonEmpty ?? department
        case .chinese:
            return localizedDepartmentZH?.nonEmpty ?? department
        }
    }

    func localizedLocation(for language: AppLanguage) -> String? {
        switch language {
        case .english:
            return localizedLocationEN?.nonEmpty ?? location
        case .chinese:
            return localizedLocationZH?.nonEmpty ?? location
        }
    }

    func localizedCompanyName(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return localizedCompanyNameEN?.nonEmpty ?? companyName
        case .chinese:
            return localizedCompanyNameZH?.nonEmpty ?? originalCompanyName?.nonEmpty ?? companyName
        }
    }

    func localizedTags(for _: AppLanguage) -> [String] {
        tags
    }
}

extension CompanyDocument {
    func localizedName(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return localizedNameEN?.nonEmpty ?? name.nonEmpty ?? originalName?.nonEmpty ?? ""
        case .chinese:
            return localizedNameZH?.nonEmpty ?? originalName?.nonEmpty ?? name.nonEmpty ?? ""
        }
    }

    func localizedSummary(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return localizedSummaryEN?.nonEmpty ?? summary
        case .chinese:
            return localizedSummaryZH?.nonEmpty ?? summary
        }
    }

    func localizedIndustry(for language: AppLanguage) -> String? {
        switch language {
        case .english:
            return localizedIndustryEN?.nonEmpty ?? industry
        case .chinese:
            return localizedIndustryZH?.nonEmpty ?? industry
        }
    }

    func localizedServiceType(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return localizedServiceTypeEN?.nonEmpty ?? serviceType
        case .chinese:
            return localizedServiceTypeZH?.nonEmpty ?? serviceType
        }
    }

    func localizedMarketRegion(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return localizedMarketRegionEN?.nonEmpty ?? marketRegion
        case .chinese:
            return localizedMarketRegionZH?.nonEmpty ?? marketRegion
        }
    }

    func localizedLocation(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return localizedLocationEN?.nonEmpty ?? location
        case .chinese:
            return localizedLocationZH?.nonEmpty ?? location
        }
    }

    func localizedHeadquarters(for language: AppLanguage) -> String? {
        switch language {
        case .english:
            return localizedHeadquartersEN?.nonEmpty ?? headquarters
        case .chinese:
            return localizedHeadquartersZH?.nonEmpty ?? headquarters
        }
    }

    func localizedCompanySize(for language: AppLanguage) -> String? {
        switch language {
        case .english:
            return localizedCompanySizeEN?.nonEmpty ?? companySize
        case .chinese:
            return localizedCompanySizeZH?.nonEmpty ?? companySize
        }
    }

    func localizedTags(for _: AppLanguage) -> [String] {
        tags
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

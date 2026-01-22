import Foundation

extension ContactDocument {
    private func nameLanguageHint(_ value: String?) -> AppLanguage? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return nil }
        if text.range(of: "[\\p{Han}]", options: .regularExpression) != nil {
            return .chinese
        }
        return .english
    }

    private func nameForLanguage(_ language: AppLanguage) -> String? {
        let nameLanguage = nameLanguageHint(name)
        let originalLanguage = nameLanguageHint(originalName)
        if nameLanguage == language { return name.nonEmpty }
        if originalLanguage == language { return originalName?.nonEmpty }
        switch language {
        case .english:
            return localizedNameEN?.nonEmpty
        case .chinese:
            return localizedNameZH?.nonEmpty
        }
    }

    func localizedName(for language: AppLanguage) -> String {
        return nameForLanguage(language) ?? name.nonEmpty ?? originalName?.nonEmpty ?? ""
    }

    func secondaryName(for language: AppLanguage) -> String? {
        guard let primaryLanguage = nameLanguageHint(name) else { return nil }
        guard primaryLanguage != language else { return nil }
        let primaryName = name.nonEmpty ?? ""
        guard !primaryName.isEmpty else { return nil }
        if primaryName == localizedName(for: language) { return nil }
        return primaryName
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
        let companyLanguage = nameLanguageHint(companyName)
        let originalLanguage = nameLanguageHint(originalCompanyName)
        if companyLanguage == language { return companyName }
        if originalLanguage == language { return originalCompanyName?.nonEmpty ?? companyName }
        switch language {
        case .english:
            return localizedCompanyNameEN?.nonEmpty ?? companyName
        case .chinese:
            return localizedCompanyNameZH?.nonEmpty ?? companyName
        }
    }

    func localizedTags(for _: AppLanguage) -> [String] {
        tags
    }
}

extension CompanyDocument {
    private func nameLanguageHint(_ value: String?) -> AppLanguage? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return nil }
        if text.range(of: "[\\p{Han}]", options: .regularExpression) != nil {
            return .chinese
        }
        return .english
    }

    private func nameForLanguage(_ language: AppLanguage) -> String? {
        let nameLanguage = nameLanguageHint(name)
        let originalLanguage = nameLanguageHint(originalName)
        if nameLanguage == language { return name.nonEmpty }
        if originalLanguage == language { return originalName?.nonEmpty }
        switch language {
        case .english:
            return localizedNameEN?.nonEmpty
        case .chinese:
            return localizedNameZH?.nonEmpty
        }
    }

    func localizedName(for language: AppLanguage) -> String {
        return nameForLanguage(language) ?? name.nonEmpty ?? originalName?.nonEmpty ?? ""
    }

    func secondaryName(for language: AppLanguage) -> String? {
        guard let primaryLanguage = nameLanguageHint(name) else { return nil }
        guard primaryLanguage != language else { return nil }
        let primaryName = name.nonEmpty ?? ""
        guard !primaryName.isEmpty else { return nil }
        if primaryName == localizedName(for: language) { return nil }
        return primaryName
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

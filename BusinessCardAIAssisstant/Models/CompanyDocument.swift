import Foundation

struct CompanyDocument: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var originalName: String?
    var summary: String
    var serviceKeywords: [String]
    var website: String
    var email: String?
    var linkedinURL: String?
    var industry: String?
    var companySize: String?
    var revenue: String?
    var foundedYear: String?
    var headquarters: String?
    var address: String
    var phone: String
    var location: String
    var originalLocation: String?
    var serviceType: String
    var targetAudience: String
    var marketRegion: String
    var notes: String
    var tags: [String]
    var relatedContactIDs: [UUID]
    var aiSummaryEN: String = ""
    var aiSummaryZH: String = ""
    var aiSummaryUpdatedAt: Date?
    var lastEnrichedFields: [String] = []
    var lastEnrichedValues: [String: String] = [:]
    var localizedNameEN: String?
    var localizedNameZH: String?
    var localizedSummaryEN: String?
    var localizedSummaryZH: String?
    var localizedIndustryEN: String?
    var localizedIndustryZH: String?
    var localizedServiceTypeEN: String?
    var localizedServiceTypeZH: String?
    var localizedMarketRegionEN: String?
    var localizedMarketRegionZH: String?
    var localizedLocationEN: String?
    var localizedLocationZH: String?
    var localizedHeadquartersEN: String?
    var localizedHeadquartersZH: String?
    var localizedCompanySizeEN: String?
    var localizedCompanySizeZH: String?
    var localizedTagsEN: [String]?
    var localizedTagsZH: [String]?
    var localizationSignatureEN: String?
    var localizationSignatureZH: String?
    var photoIDs: [UUID]
    var sourceLanguageCode: String?
    var enrichedAt: Date?
    var createdAt: Date?

    init(
        id: UUID,
        name: String,
        originalName: String?,
        summary: String,
        serviceKeywords: [String],
        website: String,
        email: String?,
        linkedinURL: String?,
        industry: String?,
        companySize: String?,
        revenue: String?,
        foundedYear: String?,
        headquarters: String?,
        address: String,
        phone: String,
        location: String,
        originalLocation: String?,
        serviceType: String,
        targetAudience: String,
        marketRegion: String,
        notes: String,
        tags: [String],
        relatedContactIDs: [UUID],
        aiSummaryEN: String = "",
        aiSummaryZH: String = "",
        aiSummaryUpdatedAt: Date? = nil,
        lastEnrichedFields: [String] = [],
        lastEnrichedValues: [String: String] = [:],
        localizedNameEN: String? = nil,
        localizedNameZH: String? = nil,
        localizedSummaryEN: String? = nil,
        localizedSummaryZH: String? = nil,
        localizedIndustryEN: String? = nil,
        localizedIndustryZH: String? = nil,
        localizedServiceTypeEN: String? = nil,
        localizedServiceTypeZH: String? = nil,
        localizedMarketRegionEN: String? = nil,
        localizedMarketRegionZH: String? = nil,
        localizedLocationEN: String? = nil,
        localizedLocationZH: String? = nil,
        localizedHeadquartersEN: String? = nil,
        localizedHeadquartersZH: String? = nil,
        localizedCompanySizeEN: String? = nil,
        localizedCompanySizeZH: String? = nil,
        localizedTagsEN: [String]? = nil,
        localizedTagsZH: [String]? = nil,
        localizationSignatureEN: String? = nil,
        localizationSignatureZH: String? = nil,
        photoIDs: [UUID],
        sourceLanguageCode: String?,
        enrichedAt: Date?,
        createdAt: Date?
    ) {
        self.id = id
        self.name = name
        self.originalName = originalName
        self.summary = summary
        self.serviceKeywords = serviceKeywords
        self.website = website
        self.email = email
        self.linkedinURL = linkedinURL
        self.industry = industry
        self.companySize = companySize
        self.revenue = revenue
        self.foundedYear = foundedYear
        self.headquarters = headquarters
        self.address = address
        self.phone = phone
        self.location = location
        self.originalLocation = originalLocation
        self.serviceType = serviceType
        self.targetAudience = targetAudience
        self.marketRegion = marketRegion
        self.notes = notes
        self.tags = tags
        self.relatedContactIDs = relatedContactIDs
        self.aiSummaryEN = aiSummaryEN
        self.aiSummaryZH = aiSummaryZH
        self.aiSummaryUpdatedAt = aiSummaryUpdatedAt
        self.lastEnrichedFields = lastEnrichedFields
        self.lastEnrichedValues = lastEnrichedValues
        self.localizedNameEN = localizedNameEN
        self.localizedNameZH = localizedNameZH
        self.localizedSummaryEN = localizedSummaryEN
        self.localizedSummaryZH = localizedSummaryZH
        self.localizedIndustryEN = localizedIndustryEN
        self.localizedIndustryZH = localizedIndustryZH
        self.localizedServiceTypeEN = localizedServiceTypeEN
        self.localizedServiceTypeZH = localizedServiceTypeZH
        self.localizedMarketRegionEN = localizedMarketRegionEN
        self.localizedMarketRegionZH = localizedMarketRegionZH
        self.localizedLocationEN = localizedLocationEN
        self.localizedLocationZH = localizedLocationZH
        self.localizedHeadquartersEN = localizedHeadquartersEN
        self.localizedHeadquartersZH = localizedHeadquartersZH
        self.localizedCompanySizeEN = localizedCompanySizeEN
        self.localizedCompanySizeZH = localizedCompanySizeZH
        self.localizedTagsEN = localizedTagsEN
        self.localizedTagsZH = localizedTagsZH
        self.localizationSignatureEN = localizationSignatureEN
        self.localizationSignatureZH = localizationSignatureZH
        self.photoIDs = photoIDs
        self.sourceLanguageCode = sourceLanguageCode
        self.enrichedAt = enrichedAt
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName
        case summary
        case serviceKeywords
        case website
        case email
        case linkedinURL
        case industry
        case companySize
        case revenue
        case foundedYear
        case headquarters
        case address
        case phone
        case location
        case originalLocation
        case serviceType
        case targetAudience
        case marketRegion
        case notes
        case tags
        case relatedContactIDs
        case aiSummaryEN
        case aiSummaryZH
        case aiSummaryUpdatedAt
        case lastEnrichedFields
        case lastEnrichedValues
        case localizedNameEN
        case localizedNameZH
        case localizedSummaryEN
        case localizedSummaryZH
        case localizedIndustryEN
        case localizedIndustryZH
        case localizedServiceTypeEN
        case localizedServiceTypeZH
        case localizedMarketRegionEN
        case localizedMarketRegionZH
        case localizedLocationEN
        case localizedLocationZH
        case localizedHeadquartersEN
        case localizedHeadquartersZH
        case localizedCompanySizeEN
        case localizedCompanySizeZH
        case localizedTagsEN
        case localizedTagsZH
        case localizationSignatureEN
        case localizationSignatureZH
        case photoIDs
        case sourceLanguageCode
        case enrichedAt
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        originalName = try container.decodeIfPresent(String.self, forKey: .originalName)
        summary = try container.decode(String.self, forKey: .summary)
        serviceKeywords = try container.decode([String].self, forKey: .serviceKeywords)
        website = try container.decode(String.self, forKey: .website)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        linkedinURL = try container.decodeIfPresent(String.self, forKey: .linkedinURL)
        industry = try container.decodeIfPresent(String.self, forKey: .industry)
        companySize = try container.decodeIfPresent(String.self, forKey: .companySize)
        revenue = try container.decodeIfPresent(String.self, forKey: .revenue)
        foundedYear = try container.decodeIfPresent(String.self, forKey: .foundedYear)
        headquarters = try container.decodeIfPresent(String.self, forKey: .headquarters)
        address = try container.decode(String.self, forKey: .address)
        phone = try container.decode(String.self, forKey: .phone)
        location = try container.decode(String.self, forKey: .location)
        originalLocation = try container.decodeIfPresent(String.self, forKey: .originalLocation)
        serviceType = try container.decode(String.self, forKey: .serviceType)
        if let audience = try container.decodeIfPresent(String.self, forKey: .targetAudience) {
            targetAudience = audience
        } else if let legacy = try container.decodeIfPresent(TargetAudience.self, forKey: .targetAudience) {
            targetAudience = legacy.rawValue
        } else {
            targetAudience = ""
        }
        marketRegion = try container.decode(String.self, forKey: .marketRegion)
        notes = try container.decode(String.self, forKey: .notes)
        tags = try container.decode([String].self, forKey: .tags)
        relatedContactIDs = try container.decode([UUID].self, forKey: .relatedContactIDs)
        aiSummaryEN = try container.decodeIfPresent(String.self, forKey: .aiSummaryEN) ?? ""
        aiSummaryZH = try container.decodeIfPresent(String.self, forKey: .aiSummaryZH) ?? ""
        aiSummaryUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .aiSummaryUpdatedAt)
        lastEnrichedFields = try container.decodeIfPresent([String].self, forKey: .lastEnrichedFields) ?? []
        lastEnrichedValues = try container.decodeIfPresent([String: String].self, forKey: .lastEnrichedValues) ?? [:]
        localizedNameEN = try container.decodeIfPresent(String.self, forKey: .localizedNameEN)
        localizedNameZH = try container.decodeIfPresent(String.self, forKey: .localizedNameZH)
        localizedSummaryEN = try container.decodeIfPresent(String.self, forKey: .localizedSummaryEN)
        localizedSummaryZH = try container.decodeIfPresent(String.self, forKey: .localizedSummaryZH)
        localizedIndustryEN = try container.decodeIfPresent(String.self, forKey: .localizedIndustryEN)
        localizedIndustryZH = try container.decodeIfPresent(String.self, forKey: .localizedIndustryZH)
        localizedServiceTypeEN = try container.decodeIfPresent(String.self, forKey: .localizedServiceTypeEN)
        localizedServiceTypeZH = try container.decodeIfPresent(String.self, forKey: .localizedServiceTypeZH)
        localizedMarketRegionEN = try container.decodeIfPresent(String.self, forKey: .localizedMarketRegionEN)
        localizedMarketRegionZH = try container.decodeIfPresent(String.self, forKey: .localizedMarketRegionZH)
        localizedLocationEN = try container.decodeIfPresent(String.self, forKey: .localizedLocationEN)
        localizedLocationZH = try container.decodeIfPresent(String.self, forKey: .localizedLocationZH)
        localizedHeadquartersEN = try container.decodeIfPresent(String.self, forKey: .localizedHeadquartersEN)
        localizedHeadquartersZH = try container.decodeIfPresent(String.self, forKey: .localizedHeadquartersZH)
        localizedCompanySizeEN = try container.decodeIfPresent(String.self, forKey: .localizedCompanySizeEN)
        localizedCompanySizeZH = try container.decodeIfPresent(String.self, forKey: .localizedCompanySizeZH)
        localizedTagsEN = try container.decodeIfPresent([String].self, forKey: .localizedTagsEN)
        localizedTagsZH = try container.decodeIfPresent([String].self, forKey: .localizedTagsZH)
        localizationSignatureEN = try container.decodeIfPresent(String.self, forKey: .localizationSignatureEN)
        localizationSignatureZH = try container.decodeIfPresent(String.self, forKey: .localizationSignatureZH)
        photoIDs = try container.decode([UUID].self, forKey: .photoIDs)
        sourceLanguageCode = try container.decodeIfPresent(String.self, forKey: .sourceLanguageCode)
        enrichedAt = try container.decodeIfPresent(Date.self, forKey: .enrichedAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(originalName, forKey: .originalName)
        try container.encode(summary, forKey: .summary)
        try container.encode(serviceKeywords, forKey: .serviceKeywords)
        try container.encode(website, forKey: .website)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(linkedinURL, forKey: .linkedinURL)
        try container.encodeIfPresent(industry, forKey: .industry)
        try container.encodeIfPresent(companySize, forKey: .companySize)
        try container.encodeIfPresent(revenue, forKey: .revenue)
        try container.encodeIfPresent(foundedYear, forKey: .foundedYear)
        try container.encodeIfPresent(headquarters, forKey: .headquarters)
        try container.encode(address, forKey: .address)
        try container.encode(phone, forKey: .phone)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(originalLocation, forKey: .originalLocation)
        try container.encode(serviceType, forKey: .serviceType)
        try container.encode(targetAudience, forKey: .targetAudience)
        try container.encode(marketRegion, forKey: .marketRegion)
        try container.encode(notes, forKey: .notes)
        try container.encode(tags, forKey: .tags)
        try container.encode(relatedContactIDs, forKey: .relatedContactIDs)
        try container.encode(aiSummaryEN, forKey: .aiSummaryEN)
        try container.encode(aiSummaryZH, forKey: .aiSummaryZH)
        try container.encodeIfPresent(aiSummaryUpdatedAt, forKey: .aiSummaryUpdatedAt)
        try container.encode(lastEnrichedFields, forKey: .lastEnrichedFields)
        try container.encode(lastEnrichedValues, forKey: .lastEnrichedValues)
        try container.encodeIfPresent(localizedNameEN, forKey: .localizedNameEN)
        try container.encodeIfPresent(localizedNameZH, forKey: .localizedNameZH)
        try container.encodeIfPresent(localizedSummaryEN, forKey: .localizedSummaryEN)
        try container.encodeIfPresent(localizedSummaryZH, forKey: .localizedSummaryZH)
        try container.encodeIfPresent(localizedIndustryEN, forKey: .localizedIndustryEN)
        try container.encodeIfPresent(localizedIndustryZH, forKey: .localizedIndustryZH)
        try container.encodeIfPresent(localizedServiceTypeEN, forKey: .localizedServiceTypeEN)
        try container.encodeIfPresent(localizedServiceTypeZH, forKey: .localizedServiceTypeZH)
        try container.encodeIfPresent(localizedMarketRegionEN, forKey: .localizedMarketRegionEN)
        try container.encodeIfPresent(localizedMarketRegionZH, forKey: .localizedMarketRegionZH)
        try container.encodeIfPresent(localizedLocationEN, forKey: .localizedLocationEN)
        try container.encodeIfPresent(localizedLocationZH, forKey: .localizedLocationZH)
        try container.encodeIfPresent(localizedHeadquartersEN, forKey: .localizedHeadquartersEN)
        try container.encodeIfPresent(localizedHeadquartersZH, forKey: .localizedHeadquartersZH)
        try container.encodeIfPresent(localizedCompanySizeEN, forKey: .localizedCompanySizeEN)
        try container.encodeIfPresent(localizedCompanySizeZH, forKey: .localizedCompanySizeZH)
        try container.encodeIfPresent(localizedTagsEN, forKey: .localizedTagsEN)
        try container.encodeIfPresent(localizedTagsZH, forKey: .localizedTagsZH)
        try container.encodeIfPresent(localizationSignatureEN, forKey: .localizationSignatureEN)
        try container.encodeIfPresent(localizationSignatureZH, forKey: .localizationSignatureZH)
        try container.encode(photoIDs, forKey: .photoIDs)
        try container.encodeIfPresent(sourceLanguageCode, forKey: .sourceLanguageCode)
        try container.encodeIfPresent(enrichedAt, forKey: .enrichedAt)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }

    func matchesSearch(_ query: String) -> Bool {
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if (originalName ?? "").lowercased().contains(lowered) { return true }
        if summary.lowercased().contains(lowered) { return true }
        if serviceKeywords.joined(separator: " ").lowercased().contains(lowered) { return true }
        if (email ?? "").lowercased().contains(lowered) { return true }
        if (industry ?? "").lowercased().contains(lowered) { return true }
        if (companySize ?? "").lowercased().contains(lowered) { return true }
        if (revenue ?? "").lowercased().contains(lowered) { return true }
        if (headquarters ?? "").lowercased().contains(lowered) { return true }
        if notes.lowercased().contains(lowered) { return true }
        if tags.joined(separator: " ").lowercased().contains(lowered) { return true }
        return false
    }

    func matches(filters: FilterOptions) -> Bool {
        if !filters.location.isEmpty {
            let query = filters.location.lowercased()
            let primaryMatch = location.lowercased().contains(query)
            let originalMatch = (originalLocation ?? "").lowercased().contains(query)
            if !primaryMatch && !originalMatch {
                return false
            }
        }
        if !filters.serviceType.isEmpty && !serviceType.lowercased().contains(filters.serviceType.lowercased()) {
            return false
        }
        if !filters.tag.isEmpty && !tags.joined(separator: " ").lowercased().contains(filters.tag.lowercased()) {
            return false
        }
        if !filters.targetAudience.isEmpty
            && !targetAudience.lowercased().contains(filters.targetAudience.lowercased()) {
            return false
        }
        if !filters.marketRegion.isEmpty && !marketRegion.lowercased().contains(filters.marketRegion.lowercased()) {
            return false
        }
        return true
    }
}

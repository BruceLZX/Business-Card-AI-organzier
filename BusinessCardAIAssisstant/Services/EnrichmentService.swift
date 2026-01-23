import Foundation
import UIKit

struct EnrichmentRequest {
    enum TargetType {
        case company
        case contact
    }

    let type: TargetType
    let name: String
    let summary: String
    let notes: String
    let tags: [String]
    let tagPool: [String]
    let photoInsights: String
    let preferredLinks: [String?]
    let context: String
}

struct EnrichmentResult {
    var summaryEN: String
    var summaryZH: String
    var tags: [String]
    var suggestedLinks: [String]
    var website: String?
    var linkedin: String?
    var phone: String?
    var address: String?
    var industry: String?
    var serviceType: String?
    var marketRegion: String?
    var companySize: String?
    var revenue: String?
    var foundedYear: String?
    var headquarters: String?
    var title: String?
    var department: String?
    var location: String?
    var email: String?
}

struct OCRParsedResult {
    enum ParsedType: String {
        case company
        case contact
        case both
    }

    let type: ParsedType
    let contact: OCRContact?
    let company: OCRCompany?
    let error: OCRError?
}

struct OCRError {
    let code: String
    let message: String
}

struct OCRContact {
    let nameEN: String
    let nameZH: String
    let title: String
    let department: String?
    let phone: String
    let email: String
    let locationEN: String?
    let locationZH: String?
    let website: String?
    let linkedin: String?
    let companyNameEN: String
    let companyNameZH: String
    let notes: String?
    let tags: [String]
}

struct OCRCompany {
    let nameEN: String
    let nameZH: String
    let summary: String
    let industry: String?
    let serviceType: String?
    let locationEN: String?
    let locationZH: String?
    let marketRegion: String?
    let website: String?
    let phone: String?
    let address: String?
    let notes: String?
    let tags: [String]
}

final class OCRExtractionService {
    private let client = OpenAIClient()

    func parse(text: String, completion: @escaping (OCRParsedResult?) -> Void) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion(nil)
            return
        }
        let prompt = AIConfig.ocrTextPrompt(ocrText: text)
        client.send(prompt: prompt, model: AIConfig.ocrTextModel, apiKey: apiKey, tools: []) { result in
            switch result {
            case .success(let responseText):
                completion(Self.parseResult(from: responseText))
            case .failure:
                completion(nil)
            }
        }
    }

    func parse(image: UIImage, completion: @escaping (OCRParsedResult?) -> Void) {
        parse(images: [image], completion: completion)
    }

    func parse(images: [UIImage], completion: @escaping (OCRParsedResult?) -> Void) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion(nil)
            return
        }
        let base64Images = images.compactMap { $0.jpegData(compressionQuality: 0.8)?.base64EncodedString() }
        guard !base64Images.isEmpty else {
            completion(nil)
            return
        }

        let prompt = AIConfig.ocrImagePrompt()
        client.sendVision(prompt: prompt, model: AIConfig.ocrVisionModel, imageBase64s: base64Images, apiKey: apiKey, tools: []) { result in
            switch result {
            case .success(let responseText):
                completion(Self.parseResult(from: responseText))
            case .failure:
                completion(nil)
            }
        }
    }

    private static func parseResult(from text: String) -> OCRParsedResult? {
        guard let json = EnrichmentService.extractJSON(from: text) else { return nil }
        guard let data = json.data(using: .utf8) else { return nil }
        guard let payload = try? JSONDecoder().decode(OCRPayload.self, from: data) else { return nil }
        if let error = payload.error, let code = error.code, !code.isEmpty {
            return OCRParsedResult(type: .company, contact: nil, company: nil, error: error.asModel())
        }
        guard let type = OCRParsedResult.ParsedType(rawValue: payload.type.lowercased()) else {
            return nil
        }
        return OCRParsedResult(
            type: type,
            contact: payload.contact?.asModel(),
            company: payload.company?.asModel(),
            error: nil
        )
    }
}

private struct OCRPayload: Decodable {
    struct OCRContactPayload: Decodable {
        let name_en: String?
        let name_zh: String?
        let title: String?
        let department: String?
        let phone: String?
        let email: String?
        let location_en: String?
        let location_zh: String?
        let location: String?
        let website: String?
        let linkedin: String?
        let company_name_en: String?
        let company_name_zh: String?
        let notes: String?
        let tags: [String]?

        func asModel() -> OCRContact {
            let filteredTags = (tags ?? []).filter { !$0.contains(" ") && !$0.contains("\t") }
            return OCRContact(
                nameEN: name_en ?? "",
                nameZH: name_zh ?? "",
                title: title ?? "",
                department: department?.isEmpty == false ? department : nil,
                phone: phone ?? "",
                email: email ?? "",
                locationEN: location_en?.isEmpty == false ? location_en : (location?.isEmpty == false ? location : nil),
                locationZH: location_zh?.isEmpty == false ? location_zh : nil,
                website: website?.isEmpty == false ? website : nil,
                linkedin: linkedin?.isEmpty == false ? linkedin : nil,
                companyNameEN: company_name_en ?? "",
                companyNameZH: company_name_zh ?? "",
                notes: notes?.isEmpty == false ? notes : nil,
                tags: filteredTags
            )
        }
    }

    struct OCRCompanyPayload: Decodable {
        let name_en: String?
        let name_zh: String?
        let summary: String?
        let industry: String?
        let service_type: String?
        let location_en: String?
        let location_zh: String?
        let location: String?
        let market_region: String?
        let website: String?
        let phone: String?
        let address: String?
        let notes: String?
        let tags: [String]?

        func asModel() -> OCRCompany {
            let filteredTags = (tags ?? []).filter { !$0.contains(" ") && !$0.contains("\t") }
            return OCRCompany(
                nameEN: name_en ?? "",
                nameZH: name_zh ?? "",
                summary: summary ?? "",
                industry: industry?.isEmpty == false ? industry : nil,
                serviceType: service_type?.isEmpty == false ? service_type : nil,
                locationEN: location_en?.isEmpty == false ? location_en : (location?.isEmpty == false ? location : nil),
                locationZH: location_zh?.isEmpty == false ? location_zh : nil,
                marketRegion: market_region?.isEmpty == false ? market_region : nil,
                website: website?.isEmpty == false ? website : nil,
                phone: phone?.isEmpty == false ? phone : nil,
                address: address?.isEmpty == false ? address : nil,
                notes: notes?.isEmpty == false ? notes : nil,
                tags: filteredTags
            )
        }
    }

    struct OCRErrorPayload: Decodable {
        let code: String?
        let message: String?

        func asModel() -> OCRError {
            OCRError(
                code: code ?? "",
                message: message ?? ""
            )
        }
    }

    let type: String
    let contact: OCRContactPayload?
    let company: OCRCompanyPayload?
    let error: OCRErrorPayload?
}

final class EnrichmentService {
    private let client = OpenAIClient()
    private let extractor = OCRExtractionService()

    func hasValidAPIKey() -> Bool {
        guard let apiKey = client.apiKey else { return false }
        return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func buildPrompt(for request: EnrichmentRequest) -> String {
        let typeLabel = request.type == .company ? "company" : "contact"
        let preferredLinks = request.preferredLinks
            .compactMap { $0 }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: ", ")
        return AIConfig.enrichmentPrompt(
            typeLabel: typeLabel,
            name: request.name,
            summary: request.summary,
            notes: request.notes,
            tags: request.tags,
            tagPool: request.tagPool,
            photoInsights: request.photoInsights,
            preferredLinks: preferredLinks,
            context: request.context,
            searchFocus: "official sources, professional profiles"
        )
    }

    func enrich(
        _ request: EnrichmentRequest,
        tagLanguage: AppLanguage,
        progress: ((EnrichmentStage) -> Void)? = nil,
        completion: @escaping (EnrichmentResult?, String?) -> Void
    ) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion(nil, "missing_api_key")
            return
        }

        let focuses = searchFocuses(for: request)
        performSearch(request: request, focus: focuses[0]) { [weak self] primary, errorCode in
            guard let self else { return }
            guard let primary else {
                self.fallbackFromInsights(request: request) { fallback in
                    if let fallback {
                        self.generateTags(
                            request: request,
                            summaryEN: fallback.summaryEN,
                            summaryZH: fallback.summaryZH,
                            tagLanguage: tagLanguage
                        ) { tags in
                            var updated = fallback
                            if !tags.isEmpty {
                                updated.tags = tags
                            }
                            completion(updated, nil)
                        }
                        return
                    }
                    completion(nil, errorCode ?? "search_failed")
                }
                return
            }
            self.performSearch(request: request, focus: focuses[1]) { secondary, _ in
                progress?(.searching(current: 2, total: 2))
                let merged = self.mergeResults(primary: primary, secondary: secondary)
                progress?(.merging)
                self.generateTags(
                    request: request,
                    summaryEN: merged.summaryEN,
                    summaryZH: merged.summaryZH,
                    tagLanguage: tagLanguage
                ) { tags in
                    var updated = merged
                    if !tags.isEmpty {
                        updated.tags = tags
                    }
                    completion(updated, nil)
                }
            }
        }
    }

    private func fallbackFromInsights(
        request: EnrichmentRequest,
        completion: @escaping (EnrichmentResult?) -> Void
    ) {
        let trimmedInsights = request.photoInsights.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContext = request.context.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasSignal = !trimmedInsights.isEmpty || !trimmedContext.isEmpty || !request.summary.isEmpty || !request.notes.isEmpty
        guard hasSignal else {
            completion(nil)
            return
        }

        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion(nil)
            return
        }

        let prompt = AIConfig.enrichmentFallbackPrompt(
            typeLabel: request.type == .company ? "company" : "contact",
            name: request.name,
            summary: request.summary,
            notes: request.notes,
            tags: request.tags,
            tagPool: request.tagPool,
            photoInsights: request.photoInsights,
            context: request.context
        )
        let model = AIConfig.enrichmentFallbackModel.isEmpty ? AIConfig.enrichmentSearchModel : AIConfig.enrichmentFallbackModel
        client.send(prompt: prompt, model: model, apiKey: apiKey, tools: []) { result in
            switch result {
            case .success(let text):
                guard let parsed = Self.parseResult(from: text), !Self.isEmptyResult(parsed) else {
                    completion(nil)
                    return
                }
                completion(parsed)
            case .failure:
                completion(nil)
            }
        }
    }

    private func searchFocuses(for request: EnrichmentRequest) -> [String] {
        if isChinaRelated(request) {
            return [
                "chinese sources, official sites, local directories",
                "international sources, english news, global databases"
            ]
        }
        return [
            "official sources, professional profiles, international sources",
            "news, press releases, market databases"
        ]
    }

    private func isChinaRelated(_ request: EnrichmentRequest) -> Bool {
        let combined = [
            request.name,
            request.summary,
            request.notes,
            request.context,
            request.photoInsights,
            request.tags.joined(separator: " ")
        ]
        .joined(separator: " ")

        if combined.range(of: "[\\p{Han}]", options: .regularExpression) != nil {
            return true
        }

        let lowered = combined.lowercased()
        if lowered.contains("china") || lowered.contains("prc") || lowered.contains("mainland") {
            return true
        }

        let preferredLinks = request.preferredLinks.compactMap { $0?.lowercased() }
        if preferredLinks.contains(where: { $0.contains(".cn") || $0.contains("://cn.") }) {
            return true
        }

        return false
    }

    func photoInsights(type: EnrichmentRequest.TargetType, images: [UIImage], completion: @escaping (String) -> Void) {
        guard !images.isEmpty else {
            completion("")
            return
        }
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion("")
            return
        }
        extractor.parse(images: images) { parsed in
            guard let parsed else {
                completion("")
                return
            }
            completion(Self.buildPhotoInsights(from: parsed, type: type))
        }
    }

    func generateTagsForCreate(
        request: EnrichmentRequest,
        tagLanguage: AppLanguage,
        completion: @escaping ([String]) -> Void
    ) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion([])
            return
        }
        let (summaryEN, summaryZH) = summaryForTagging(request.summary)
        generateTags(
            request: request,
            summaryEN: summaryEN,
            summaryZH: summaryZH,
            tagLanguage: tagLanguage,
            completion: completion
        )
    }

    private func summaryForTagging(_ summary: String) -> (String, String) {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", "") }
        if trimmed.range(of: "[\\p{Han}]", options: .regularExpression) != nil {
            return ("", trimmed)
        }
        return (trimmed, "")
    }

    private func performSearch(
        request: EnrichmentRequest,
        focus: String,
        completion: @escaping (EnrichmentResult?, String?) -> Void
    ) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion(nil, "missing_api_key")
            return
        }
        let preferredLinks = request.preferredLinks
            .compactMap { $0 }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: ", ")
        let prompt = AIConfig.enrichmentPrompt(
            typeLabel: request.type == .company ? "company" : "contact",
            name: request.name,
            summary: request.summary,
            notes: request.notes,
            tags: request.tags,
            tagPool: request.tagPool,
            photoInsights: request.photoInsights,
            preferredLinks: preferredLinks,
            context: request.context,
            searchFocus: focus
        )
        let primaryModel = AIConfig.enrichmentSearchModel
        let fallbackModel = AIConfig.enrichmentFallbackModel

        func handleResult(_ result: Result<String, Error>, allowFallback: Bool) {
            switch result {
            case .success(let text):
                guard let parsed = Self.parseResult(from: text) else {
                    completion(nil, "parse_failed")
                    return
                }
                if Self.isEmptyResult(parsed) {
                    completion(nil, "empty_result")
                    return
                }
                completion(parsed, nil)
            case .failure:
                if allowFallback, !fallbackModel.isEmpty, fallbackModel != primaryModel {
                    client.send(
                        prompt: prompt,
                        model: fallbackModel,
                        apiKey: apiKey,
                        tools: [["type": "web_search"]]
                    ) { fallbackResult in
                        handleResult(fallbackResult, allowFallback: false)
                    }
                } else {
                    completion(nil, "request_failed")
                }
            }
        }

        client.send(
            prompt: prompt,
            model: primaryModel,
            apiKey: apiKey,
            tools: [["type": "web_search"]]
        ) { result in
            handleResult(result, allowFallback: true)
        }
    }

    private func generateTags(
        request: EnrichmentRequest,
        summaryEN: String,
        summaryZH: String,
        tagLanguage: AppLanguage,
        completion: @escaping ([String]) -> Void
    ) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion([])
            return
        }
        let prompt = AIConfig.taggingPrompt(
            typeLabel: request.type == .company ? "company" : "contact",
            tagPool: request.tagPool,
            existingTags: request.tags,
            summaryEN: summaryEN,
            summaryZH: summaryZH,
            context: request.context,
            photoInsights: request.photoInsights,
            targetLanguage: tagLanguage == .chinese ? "Chinese" : "English"
        )
        client.send(prompt: prompt, model: AIConfig.taggingModel, apiKey: apiKey, tools: []) { result in
            switch result {
            case .success(let text):
                let tags = Self.parseTags(from: text)
                completion(tags)
            case .failure:
                completion([])
            }
        }
    }

    private func mergeResults(primary: EnrichmentResult, secondary: EnrichmentResult?) -> EnrichmentResult {
        guard let secondary else { return primary }
        var merged = primary
        if merged.summaryEN.isEmpty { merged.summaryEN = secondary.summaryEN }
        if merged.summaryZH.isEmpty { merged.summaryZH = secondary.summaryZH }
        let mergedTags = Array(Set(merged.tags + secondary.tags))
        merged.tags = mergedTags
        merged.suggestedLinks = Array(Set(merged.suggestedLinks + secondary.suggestedLinks))
        if merged.website == nil || merged.website?.isEmpty == true { merged.website = secondary.website }
        if merged.linkedin == nil || merged.linkedin?.isEmpty == true { merged.linkedin = secondary.linkedin }
        if merged.phone == nil || merged.phone?.isEmpty == true { merged.phone = secondary.phone }
        if merged.address == nil || merged.address?.isEmpty == true { merged.address = secondary.address }
        if merged.industry == nil || merged.industry?.isEmpty == true { merged.industry = secondary.industry }
        if merged.serviceType == nil || merged.serviceType?.isEmpty == true { merged.serviceType = secondary.serviceType }
        if merged.marketRegion == nil || merged.marketRegion?.isEmpty == true { merged.marketRegion = secondary.marketRegion }
        if merged.companySize == nil || merged.companySize?.isEmpty == true { merged.companySize = secondary.companySize }
        if merged.revenue == nil || merged.revenue?.isEmpty == true { merged.revenue = secondary.revenue }
        if merged.foundedYear == nil || merged.foundedYear?.isEmpty == true { merged.foundedYear = secondary.foundedYear }
        if merged.headquarters == nil || merged.headquarters?.isEmpty == true { merged.headquarters = secondary.headquarters }
        if merged.title == nil || merged.title?.isEmpty == true { merged.title = secondary.title }
        if merged.department == nil || merged.department?.isEmpty == true { merged.department = secondary.department }
        if merged.location == nil || merged.location?.isEmpty == true { merged.location = secondary.location }
        if merged.email == nil || merged.email?.isEmpty == true { merged.email = secondary.email }
        return merged
    }

    private static func buildPhotoInsights(from parsed: OCRParsedResult, type: EnrichmentRequest.TargetType) -> String {
        var parts: [String] = []
        func append(_ label: String, _ value: String?) {
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            parts.append("\(label): \(value)")
        }
        if let company = parsed.company, type == .company || parsed.type == .both {
            append("Company Name EN", company.nameEN)
            append("Company Name ZH", company.nameZH)
            append("Summary", company.summary)
            append("Industry", company.industry)
            append("Service Type", company.serviceType)
            append("Market Region", company.marketRegion)
            append("Location EN", company.locationEN)
            append("Location ZH", company.locationZH)
            append("Website", company.website)
            append("Phone", company.phone)
            append("Address", company.address)
        }
        if let contact = parsed.contact, type == .contact || parsed.type == .both {
            append("Contact Name EN", contact.nameEN)
            append("Contact Name ZH", contact.nameZH)
            append("Title", contact.title)
            append("Department", contact.department)
            append("Company Name EN", contact.companyNameEN)
            append("Company Name ZH", contact.companyNameZH)
            append("Phone", contact.phone)
            append("Email", contact.email)
            append("Location EN", contact.locationEN)
            append("Location ZH", contact.locationZH)
            append("Website", contact.website)
            append("LinkedIn", contact.linkedin)
        }
        return parts.joined(separator: " | ")
    }

    private static func parseResult(from text: String) -> EnrichmentResult? {
        guard let json = extractJSON(from: text) else { return nil }
        guard let data = json.data(using: .utf8) else { return nil }
        guard let payload = try? JSONDecoder().decode(EnrichmentPayload.self, from: data) else { return nil }
        return EnrichmentResult(
            summaryEN: payload.summary_en ?? "",
            summaryZH: payload.summary_zh ?? "",
            tags: payload.tags ?? [],
            suggestedLinks: payload.links ?? [],
            website: payload.website,
            linkedin: payload.linkedin,
            phone: payload.phone,
            address: payload.address,
            industry: payload.industry,
            serviceType: payload.service_type,
            marketRegion: payload.market_region,
            companySize: payload.company_size,
            revenue: payload.revenue,
            foundedYear: payload.founded_year,
            headquarters: payload.headquarters,
            title: payload.title,
            department: payload.department,
            location: payload.location,
            email: payload.email
        )
    }

    private static func isEmptyResult(_ result: EnrichmentResult) -> Bool {
        let values: [String] = [
            result.summaryEN,
            result.summaryZH,
            result.website ?? "",
            result.linkedin ?? "",
            result.phone ?? "",
            result.address ?? "",
            result.industry ?? "",
            result.serviceType ?? "",
            result.marketRegion ?? "",
            result.companySize ?? "",
            result.revenue ?? "",
            result.foundedYear ?? "",
            result.headquarters ?? "",
            result.title ?? "",
            result.department ?? "",
            result.location ?? "",
            result.email ?? ""
        ]
        let hasValue = values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return !hasValue && result.tags.isEmpty && result.suggestedLinks.isEmpty
    }

    private static func parseTags(from text: String) -> [String] {
        guard let json = extractJSON(from: text) else { return [] }
        guard let data = json.data(using: .utf8) else { return [] }
        guard let payload = try? JSONDecoder().decode(TaggingPayload.self, from: data) else { return [] }
        return (payload.tags ?? []).filter { !$0.contains(" ") && !$0.contains("\t") }
    }

    static func extractJSON(from text: String) -> String? {
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return nil
    }
}

private struct EnrichmentPayload: Decodable {
    let summary_en: String?
    let summary_zh: String?
    let tags: [String]?
    let links: [String]?
    let website: String?
    let linkedin: String?
    let phone: String?
    let address: String?
    let industry: String?
    let service_type: String?
    let market_region: String?
    let company_size: String?
    let revenue: String?
    let founded_year: String?
    let headquarters: String?
    let title: String?
    let department: String?
    let location: String?
    let email: String?
}

private struct TaggingPayload: Decodable {
    let tags: [String]?
}

private final class OpenAIClient {
    var apiKey: String? {
        if let override = AIConfig.apiKey, !override.isEmpty {
            return override
        }
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }
        return SecretsLoader.apiKeyFromBundle()
    }

    func send(prompt: String, model: String, apiKey: String, tools: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            completion(.failure(OpenAIClientError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model,
            "input": prompt,
            "tools": tools
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                debugPrint("OpenAIClient error status \(http.statusCode): \(body.prefix(1000))")
                completion(.failure(OpenAIClientError.httpStatus(http.statusCode)))
                return
            }
            guard let data else {
                completion(.failure(OpenAIClientError.emptyResponse))
                return
            }
            do {
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let text = response.output_text ?? response.outputText() {
                    completion(.success(text))
                } else {
                    completion(.failure(OpenAIClientError.emptyResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func sendVision(prompt: String, model: String, imageBase64s: [String], apiKey: String, tools: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            completion(.failure(OpenAIClientError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var content: [[String: Any]] = [
            [
                "type": "input_text",
                "text": prompt
            ]
        ]
        for base64 in imageBase64s {
            content.append([
                "type": "input_image",
                "image_url": "data:image/jpeg;base64,\(base64)"
            ])
        }

        let input: [[String: Any]] = [
            [
                "role": "user",
                "content": content
            ]
        ]

        let payload: [String: Any] = [
            "model": model,
            "input": input,
            "tools": tools
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                debugPrint("OpenAIClient vision error status \(http.statusCode): \(body.prefix(1000))")
                completion(.failure(OpenAIClientError.httpStatus(http.statusCode)))
                return
            }
            guard let data else {
                completion(.failure(OpenAIClientError.emptyResponse))
                return
            }
            do {
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let text = response.output_text ?? response.outputText() {
                    completion(.success(text))
                } else {
                    completion(.failure(OpenAIClientError.emptyResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

private enum OpenAIClientError: Error {
    case invalidURL
    case emptyResponse
    case httpStatus(Int)
}

private struct OpenAIResponse: Decodable {
    struct OutputItem: Decodable {
        struct Content: Decodable {
            let type: String?
            let text: String?
        }

        let content: [Content]?
    }

    let output: [OutputItem]?
    let output_text: String?

    func outputText() -> String? {
        let texts = output?
            .compactMap { $0.content }
            .flatMap { $0 }
            .filter { $0.type == "output_text" }
            .compactMap { $0.text }
        return texts?.joined(separator: "\n")
    }
}

private enum SecretsLoader {
    static func apiKeyFromBundle() -> String? {
        if let info = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, !info.isEmpty {
            return info
        }
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "xcconfig") else {
            return nil
        }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        for line in content.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if key == "OPENAI_API_KEY" {
                let raw = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                return raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
        }
        return nil
    }
}

enum ClassifiedDocumentType: String, Decodable {
    case company
    case contact
}

final class DocumentClassifier {
    private let client = OpenAIClient()

    func classify(text: String, completion: @escaping (ClassifiedDocumentType) -> Void) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion(.company)
            return
        }
        let prompt = AIConfig.classifierPrompt(ocrText: text)
        client.send(prompt: prompt, model: AIConfig.classifierModel, apiKey: apiKey, tools: []) { result in
            switch result {
            case .success(let responseText):
                if let json = EnrichmentService.extractJSON(from: responseText),
                   let data = json.data(using: .utf8),
                   let payload = try? JSONDecoder().decode(ClassificationPayload.self, from: data),
                   let type = ClassifiedDocumentType(rawValue: payload.type.lowercased()) {
                    completion(type)
                } else {
                    completion(.company)
                }
            case .failure:
                completion(.company)
            }
        }
    }
}

private struct ClassificationPayload: Decodable {
    let type: String
}

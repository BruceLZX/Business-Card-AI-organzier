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
    let rawOCRText: String
    let preferredLinks: [String?]
    let context: String
}

struct EnrichmentResult {
    let summaryEN: String
    let summaryZH: String
    let tags: [String]
    let suggestedLinks: [String]
    let website: String?
    let linkedin: String?
    let phone: String?
    let address: String?
    let industry: String?
    let companySize: String?
    let revenue: String?
    let foundedYear: String?
    let headquarters: String?
    let title: String?
    let department: String?
    let location: String?
    let email: String?
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

protocol EnrichmentProviding {
    func buildPrompt(for request: EnrichmentRequest) -> String
    func enrich(_ request: EnrichmentRequest, completion: @escaping (EnrichmentResult?) -> Void)
}

final class EnrichmentService: EnrichmentProviding {
    private let client = OpenAIClient()
    private let thinkingModel = "o3-mini"

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
            rawOCRText: request.rawOCRText,
            preferredLinks: preferredLinks,
            context: request.context
        )
    }

    func enrich(_ request: EnrichmentRequest, completion: @escaping (EnrichmentResult?) -> Void) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion(nil)
            return
        }

        let prompt = buildPrompt(for: request)
        client.send(prompt: prompt, model: AIConfig.enrichmentModel, apiKey: apiKey, tools: [["type": "web_search"]]) { result in
            switch result {
            case .success(let text):
                completion(Self.parseResult(from: text))
            case .failure:
                completion(nil)
            }
        }
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
    let company_size: String?
    let revenue: String?
    let founded_year: String?
    let headquarters: String?
    let title: String?
    let department: String?
    let location: String?
    let email: String?
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

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
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

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
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

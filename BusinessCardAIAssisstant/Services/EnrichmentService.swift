import Foundation

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
    let rawOCRText: String
}

struct EnrichmentResult {
    let summary: String
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

protocol EnrichmentProviding {
    func buildPrompt(for request: EnrichmentRequest) -> String
    func enrich(_ request: EnrichmentRequest, completion: @escaping (EnrichmentResult?) -> Void)
}

final class EnrichmentService: EnrichmentProviding {
    private let client = OpenAIClient()

    func buildPrompt(for request: EnrichmentRequest) -> String {
        let typeLabel = request.type == .company ? "company" : "contact"
        return """
        You are a research assistant. Use web search to enrich the following \(typeLabel) profile.
        Return a single JSON object only. No markdown, no commentary.

        If type is company, include keys:
        summary, tags, links, website, linkedin, phone, address, industry, company_size, revenue, founded_year, headquarters.

        If type is contact, include keys:
        summary, tags, links, website, linkedin, phone, email, title, department, location.

        - summary: concise, factual, <= 60 words.
        - tags: 3-6 short tags.
        - links: official or authoritative URLs only.
        - leave unknown fields as empty string or empty array.
        - do not invent facts; prefer official sources.

        Name: \(request.name)
        Summary: \(request.summary)
        Notes: \(request.notes)
        Tags: \(request.tags.joined(separator: ", "))
        OCR Text: \(request.rawOCRText)
        """
    }

    func enrich(_ request: EnrichmentRequest, completion: @escaping (EnrichmentResult?) -> Void) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion(nil)
            return
        }

        let prompt = buildPrompt(for: request)
        client.send(prompt: prompt, apiKey: apiKey, tools: [["type": "web_search"]]) { result in
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
            summary: payload.summary ?? "",
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
    let summary: String?
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
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }
        return SecretsLoader.apiKeyFromBundle()
    }

    func send(prompt: String, apiKey: String, tools: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            completion(.failure(OpenAIClientError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
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
        guard let content = try? String(contentsOf: url) else { return nil }
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

        let prompt = """
        Decide whether the OCR text describes a person/contact or a company/brochure.
        Return a single JSON object only with key \"type\" and value \"contact\" or \"company\".
        No markdown, no extra text.
        OCR Text:
        \(text)
        """

        client.send(prompt: prompt, apiKey: apiKey, tools: []) { result in
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

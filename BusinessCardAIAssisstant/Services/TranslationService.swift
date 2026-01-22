import Foundation

struct TranslationRequest {
    let fields: [String: String]
    let targetLanguage: AppLanguage
}

struct TranslationResult {
    let fields: [String: String]
}

final class TranslationService {
    private let client = TranslationClient()

    func hasValidAPIKey() -> Bool {
        guard let apiKey = client.apiKey else { return false }
        return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func translate(_ request: TranslationRequest, completion: @escaping (TranslationResult?) -> Void) {
        guard let apiKey = client.apiKey, !apiKey.isEmpty else {
            completion(nil)
            return
        }
        let target = request.targetLanguage == .chinese ? "Chinese" : "English"
        let prompt = AIConfig.translationPrompt(
            targetLanguage: target,
            fields: request.fields
        )
        client.send(prompt: prompt, model: AIConfig.translationModel, apiKey: apiKey) { result in
            switch result {
            case .success(let text):
                completion(Self.parseResult(from: text))
            case .failure:
                completion(nil)
            }
        }
    }

    private static func parseResult(from text: String) -> TranslationResult? {
        guard let json = EnrichmentService.extractJSON(from: text) else { return nil }
        guard let data = json.data(using: .utf8) else { return nil }
        guard let payload = try? JSONDecoder().decode(TranslationPayload.self, from: data) else { return nil }
        return TranslationResult(fields: payload.fields ?? [:])
    }
}

private struct TranslationPayload: Decodable {
    let fields: [String: String]?
}

private final class TranslationClient {
    var apiKey: String? {
        if let override = AIConfig.apiKey, !override.isEmpty {
            return override
        }
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }
        if let info = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, !info.isEmpty {
            return info
        }
        return SecretsLoader.apiKeyFromBundle()
    }

    func send(prompt: String, model: String, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            completion(.failure(TranslationClientError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model,
            "input": prompt
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
                debugPrint("TranslationClient error status \(http.statusCode): \(body.prefix(1000))")
                completion(.failure(TranslationClientError.httpStatus(http.statusCode)))
                return
            }
            guard let data else {
                completion(.failure(TranslationClientError.emptyResponse))
                return
            }
            do {
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let text = response.output_text ?? response.outputText() {
                    completion(.success(text))
                } else {
                    completion(.failure(TranslationClientError.emptyResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

private enum TranslationClientError: Error {
    case invalidURL
    case emptyResponse
    case httpStatus(Int)
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

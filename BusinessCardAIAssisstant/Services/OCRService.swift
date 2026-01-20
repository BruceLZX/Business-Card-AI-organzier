import Foundation
import UIKit
import Vision

struct OCRResult {
    let text: String
    let lines: [String]
}

final class OCRService {
    func recognizeText(in image: UIImage, completion: @escaping (OCRResult?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            let combined = lines.joined(separator: "\n")
            completion(OCRResult(text: combined, lines: lines))
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en_US", "en_GB", "zh-Hans", "zh-Hant"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(nil)
            }
        }
    }
}

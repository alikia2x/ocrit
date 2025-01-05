import Vision
import Cocoa

final class CGImageOCR {

    let image: CGImage
    let customLanguages: [String]

    init(image: CGImage, customLanguages: [String]) {
        self.image = image
        self.customLanguages = customLanguages
    }

    private var request: VNRecognizeTextRequest?
    private var handler: VNImageRequestHandler?

    func run(fast: Bool) async throws -> OCRResult {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<OCRResult, Error>) -> Void in
            performRequest(with: image, level: fast ? .fast : .accurate) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(throwing: Failure("No results"))
                        return
                    }

                    var lines: [OCRLine] = []
                    let imageWidth = Double(self.image.width)
                    let imageHeight = Double(self.image.height)
                    
                    for observation in observations {
                        let candidate = observation.topCandidates(1)[0]
                        let boundingBox = observation.boundingBox
                        
                        // Convert normalized coordinates to pixel coordinates
                        let x = boundingBox.origin.x * imageWidth
                        let y = (1 - boundingBox.origin.y - boundingBox.size.height) * imageHeight
                        let width = boundingBox.size.width * imageWidth
                        let height = boundingBox.size.height * imageHeight
                        
                        let line = OCRLine(
                            text: candidate.string,
                            confidence: Double(candidate.confidence),
                            position: [x, y, width, height]
                        )
                        lines.append(line)
                    }

                    let result = OCRResult(
                        lines: lines,
                        suggestedFilename: "ocr_result"
                    )
                    
                    continuation.resume(with: .success(result))
                }
            }
        }
    }

    func performRequest(with image: CGImage, level: VNRequestTextRecognitionLevel, completion: @escaping VNRequestCompletionHandler) {
        let newHandler = VNImageRequestHandler(cgImage: image)

        let newRequest = VNRecognizeTextRequest(completionHandler: completion)
        newRequest.recognitionLevel = level

        do {
            if let customLanguages = try resolveLanguages(for: newRequest) {
                newRequest.recognitionLanguages = customLanguages
            }
        } catch {
            completion(newRequest, error)
            return
        }

        request = newRequest
        handler = newHandler

        do {
            try newHandler.perform([newRequest])
        } catch {
            completion(newRequest, error)
        }
    }

    private func resolveLanguages(for request: VNRecognizeTextRequest) throws -> [String]? {
        try request.validateLanguages(with: customLanguages)
    }
}

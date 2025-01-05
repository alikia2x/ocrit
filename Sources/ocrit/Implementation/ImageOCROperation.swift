import Vision
import Cocoa

final class ImageOCROperation: OCROperation {

    let imageURL: URL
    let customLanguages: [String]
    
    init(fileURL: URL, customLanguages: [String]) {
        self.imageURL = fileURL
        self.customLanguages = customLanguages
    }

    func run(fast: Bool) throws -> AsyncThrowingStream<OCRResult, Error> {
        guard let image = NSImage(contentsOf: imageURL) else {
            throw Failure("Couldn't read image at \(imageURL.path)")
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw Failure("Couldn't read CGImage fir \(imageURL.lastPathComponent)")
        }

        let filename = imageURL.deletingPathExtension().lastPathComponent

        let ocr = CGImageOCR(image: cgImage, customLanguages: customLanguages)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var result = try await ocr.run(fast: fast)
                    result.suggestedFilename = filename
                    
                    continuation.yield(result)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

}

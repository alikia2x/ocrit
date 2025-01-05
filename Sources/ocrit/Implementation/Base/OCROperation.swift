import Foundation

struct OCRLine {
    let text: String
    let confidence: Double
    let position: [Double]
}

struct OCRResult {
    var text: String {
        lines.map { $0.text }.joined(separator: "\n")
    }
    var lines: [OCRLine]
    var suggestedFilename: String
}

protocol OCROperation {
    init(fileURL: URL, customLanguages: [String])
    func run(fast: Bool) throws -> AsyncThrowingStream<OCRResult, Error>
}

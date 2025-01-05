import ArgumentParser
import Foundation
import PathKit

enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case txt
    case json
    
    init?(argument: String) {
        self.init(rawValue: argument.lowercased())
    }
}

enum Output {
    case stdOutput
    case path(Path, format: OutputFormat)
    
    var format: OutputFormat {
        switch self {
        case .stdOutput: return .txt
        case .path(_, let format): return format
        }
    }
}

struct RecognitionResult: Codable {
    let lines: [RecognitionLine]
}

struct RecognitionLine: Codable {
    let text: String
    let confidence: Double
    let position: [Int]
}

extension Output: ExpressibleByArgument {
    init?(argument: String) {
        if argument == "-" {
            self = .stdOutput
            return
        }

        let path = Path(argument).absolute()
        let format = OutputFormat(rawValue: path.extension?.lowercased() ?? "txt") ?? .txt
        self = .path(path, format: format)
    }
}

extension Output {
    var isStdOutput: Bool {
        switch self {
        case .stdOutput: true
        default: false
        }
    }

    var path: Path? {
        switch self {
        case let .path(path, _): path
        default: nil
        }
    }
    
    func write(_ lines: [(text: String, confidence: Double, position: [Int])]) throws {
        switch self.format {
        case .txt:
            try writeText(lines)
        case .json:
            try writeJSON(lines)
        }
    }
    
    private func writeText(_ lines: [(text: String, confidence: Double, position: [Int])]) throws {
        let content = lines.map { $0.text }.joined(separator: "\n")
        if isStdOutput {
            print(content)
        } else if let path = path {
            try path.write(content)
        }
    }
    
    private func writeJSON(_ lines: [(text: String, confidence: Double, position: [Int])]) throws {
        let result = RecognitionResult(lines: lines.map {
            RecognitionLine(text: $0.text, confidence: $0.confidence, position: $0.position)
        })
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(result)
        
        if isStdOutput {
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else if let path = path {
            try path.write(data)
        }
    }
}

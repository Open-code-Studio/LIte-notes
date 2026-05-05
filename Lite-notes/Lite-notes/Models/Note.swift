import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var templateId: UUID?
    
    init(title: String = "", content: String = "", templateId: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.templateId = templateId
    }
    
    @Relationship(deleteRule: .nullify)
    var template: Template?
}

@Model
final class Template {
    var id: UUID
    var name: String
    var content: String
    var placeholderKeys: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String = "", content: String = "") {
        self.id = UUID()
        self.name = name
        self.content = content
        self.placeholderKeys = Self.extractPlaceholderKeys(from: content)
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func extractPlaceholderKeys(from content: String) -> [String] {
        let pattern = "\\{\\{(\\w+)\\}\\}"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: content, range: NSRange(content.startIndex..., in: content)) ?? []
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[range])
        }
    }
    
    func applyPlaceholderValues(_ values: [String: String]) -> String {
        var result = content
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }
    
    @Relationship(inverse: \Note.template)
    var notes: [Note]?
}
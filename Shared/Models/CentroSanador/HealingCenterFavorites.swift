import Foundation

enum HealingCenterFavorites {
    static let storageKey = "healing_center.favorite_situation_ids"

    static func decode(_ value: String) -> Set<String> {
        guard let data = value.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(ids)
    }

    static func encode(_ ids: Set<String>) -> String {
        let sortedIDs = ids.sorted()
        guard let data = try? JSONEncoder().encode(sortedIDs) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}


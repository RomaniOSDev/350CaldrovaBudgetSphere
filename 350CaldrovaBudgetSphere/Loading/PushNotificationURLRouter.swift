import Foundation

final class PushNotificationURLRouter {
    static let shared = PushNotificationURLRouter()

    private init() {}

    private var pendingURL: URL?

    func setPendingURL(_ url: URL) {
        pendingURL = url
    }

    func consumePendingURL() -> URL? {
        defer { pendingURL = nil }
        return pendingURL
    }

    func extractURL(from userInfo: [AnyHashable: Any]) -> URL? {
        if let url = parseURL(from: userInfo, key: "url") { return url }

        if let dataDict = userInfo["data"] as? [AnyHashable: Any],
           let url = parseURL(from: dataDict, key: "url") {
            return url
        }

        if let messageDict = userInfo["message"] as? [AnyHashable: Any] {
            if let url = parseURL(from: messageDict, key: "url") { return url }

            if let messageDataDict = messageDict["data"] as? [AnyHashable: Any],
               let url = parseURL(from: messageDataDict, key: "url") {
                return url
            }
        }

        if let url = parseURL(from: userInfo, key: "gcm.notification.url") { return url }
        if let url = parseURL(from: userInfo, key: "custom.url") { return url }

        return nil
    }

    func extractMessageID(from userInfo: [AnyHashable: Any]) -> String? {
        if let value = parseString(from: userInfo, key: "message_id") {
            return value
        }
        if let dataDict = userInfo["data"] as? [AnyHashable: Any],
           let value = parseString(from: dataDict, key: "message_id") {
            return value
        }
        if let messageDict = userInfo["message"] as? [AnyHashable: Any] {
            if let value = parseString(from: messageDict, key: "message_id") {
                return value
            }
            if let messageDataDict = messageDict["data"] as? [AnyHashable: Any],
               let value = parseString(from: messageDataDict, key: "message_id") {
                return value
            }
        }
        return nil
    }

    private func parseURL(from dict: [AnyHashable: Any], key: String) -> URL? {
        guard let urlString = parseString(from: dict, key: key),
              !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return URL(string: urlString)
    }

    private func parseString(from dict: [AnyHashable: Any], key: String) -> String? {
        guard let raw = dict[key] else { return nil }
        if let string = raw as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = raw as? NSNumber {
            return number.stringValue
        }
        return nil
    }
}

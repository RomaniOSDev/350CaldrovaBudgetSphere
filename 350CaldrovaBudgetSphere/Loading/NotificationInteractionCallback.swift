import Foundation
import UIKit
import AppsFlyerLib

final class NotificationInteractionCallback {
    static let shared = NotificationInteractionCallback()

    private init() {}

    func handleNotificationOpen(userInfo: [AnyHashable: Any]) {
        let messageId = PushNotificationURLRouter.shared.extractMessageID(from: userInfo) ?? ""
        let afId = AppsFlyerLib.shared().getAppsFlyerUID()
        send(messageId: messageId, afId: afId)
    }

    private func send(messageId: String, afId: String) {
        guard let url = makeInteractionURL(messageId: messageId) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["af_id": afId])

        URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 400 || status == 405 else { return }
            DispatchQueue.main.async {
                self?.presentErrorAlert(statusCode: status)
            }
        }.resume()
    }

    private func makeInteractionURL(messageId: String) -> URL? {
        guard let configURL = ConfigManager.shared.configEndpointURL,
              var components = URLComponents(url: configURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let path = components.path
        if path.hasSuffix("config.php") {
            components.path = String(path.dropLast("config.php".count)) + "interaction.php"
        } else {
            let directory = (path as NSString).deletingLastPathComponent
            components.path = (directory as NSString).appendingPathComponent("interaction.php")
        }
        components.queryItems = [URLQueryItem(name: "message_id", value: messageId)]
        return components.url
    }

    private func presentErrorAlert(statusCode: Int) {
        let title: String
        let message: String
        switch statusCode {
        case 400:
            title = "400 (Bad Request)"
            message = "message_id is missing or invalid, or af_id is empty."
        case 405:
            title = "405 (Method Not Allowed)"
            message = "Only the PUT method is allowed."
        default:
            return
        }

        guard let presenter = topViewController() else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }

    private func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? scenes.flatMap(\.windows).first
        guard var top = window?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

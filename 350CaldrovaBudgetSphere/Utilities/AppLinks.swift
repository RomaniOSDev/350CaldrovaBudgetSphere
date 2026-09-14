import StoreKit
import UIKit

enum AppLinks: String {
    case privacy = "https://caldrovabudget350sphere.site/privacy/461"
    case terms = "https://caldrovabudget350sphere.site/terms/461"

    static func rateApp() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { scene in
            scene as? UIWindowScene
        }
        let windowScene = scenes.first(where: { scene in
            scene.activationState == .foregroundActive
        }) ?? scenes.first
        if let windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

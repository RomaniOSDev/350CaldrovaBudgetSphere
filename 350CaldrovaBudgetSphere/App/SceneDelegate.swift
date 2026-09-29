import UIKit
import SwiftUI
import AppsFlyerLib

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = LoadingManager.shared.makeRootViewController()
        window?.makeKeyAndVisible()
        handleDeepLinkConnectionOptions(connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        AppsFlyerLib.shared().handleOpen(url, options: nil)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {
        routePendingPushURLIfNeeded(in: scene)
    }

    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}

    private func handleDeepLinkConnectionOptions(_ options: UIScene.ConnectionOptions) {
        if let urlContext = options.urlContexts.first {
            AppsFlyerLib.shared().handleOpen(urlContext.url, options: nil)
        }
        if let activity = options.userActivities.first {
            AppsFlyerLib.shared().continue(activity, restorationHandler: nil)
        }
    }

    private func routePendingPushURLIfNeeded(in scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        guard let url = PushNotificationURLRouter.shared.consumePendingURL() else { return }

        let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
        window?.rootViewController = WebviewVC(url: url)
    }
}

import AudioToolbox
import UIKit

enum FocusCue {
    static func play(haptic: Bool, sound: Bool) {
        if haptic {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if sound {
            AudioServicesPlaySystemSound(1025)
        }
    }
}

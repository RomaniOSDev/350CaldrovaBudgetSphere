import SwiftUI
import UIKit

enum KeyboardFold {
    static func putAway() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct KeyboardDismissTap: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        KeyboardDismissHost()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private final class KeyboardDismissHost: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        isUserInteractionEnabled = false
        backgroundColor = .clear
        guard let window else { return }
        if window.gestureRecognizers?.contains(where: { $0.name == Self.recognizerName }) == true {
            return
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(fold))
        tap.cancelsTouchesInView = false
        tap.requiresExclusiveTouchType = false
        tap.name = Self.recognizerName
        tap.delegate = KeyboardDismissGate.shared
        window.addGestureRecognizer(tap)
    }

    @objc private func fold() {
        KeyboardFold.putAway()
    }

    private static let recognizerName = "ledger.keyboard.dismiss"
}

private final class KeyboardDismissGate: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissGate()

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView || current is UISearchBar {
                return false
            }
            view = current.superview
        }
        return true
    }
}

private struct KeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    KeyboardFold.putAway()
                }
                .fontWeight(.semibold)
                .foregroundColor(Palette.primary)
            }
        }
    }
}

extension View {
    func foldKeyboardOnTap() -> some View {
        background(KeyboardDismissTap())
    }

    func keyboardDoneButton() -> some View {
        modifier(KeyboardDoneToolbar())
    }
}

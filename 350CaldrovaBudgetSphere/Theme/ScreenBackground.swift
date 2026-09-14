import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("BgLedger")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.22)
                    }
                    .clipped()
                    .ignoresSafeArea()
                    .ignoresSafeArea(.keyboard)
            }
    }
}

extension View {
    func studioBackdrop() -> some View {
        modifier(ScreenBackground())
    }
}

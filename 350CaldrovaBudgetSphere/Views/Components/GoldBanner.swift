import SwiftUI

struct GoldBanner: View {
    let imageName: String
    var height: CGFloat = 128

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                Palette.surface
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Palette.primary.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: Palette.primary.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

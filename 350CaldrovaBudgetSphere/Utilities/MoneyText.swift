import SwiftUI

struct MoneyText: View {
    let amount: Double
    var size: Font = .system(.body, design: .monospaced)

    var body: some View {
        Text(MoneyText.format(amount))
            .font(size)
            .monospacedDigit()
            .foregroundColor(Palette.primary)
    }

    static func format(_ amount: Double) -> String {
        let value = amount.isFinite ? amount : 0
        if let text = formatter.string(from: NSNumber(value: value)) {
            return text
        }
        return String(format: "%.2f", value)
    }

    static func parse(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        if let number = formatter.number(from: trimmed) {
            let value = number.doubleValue
            if value > 0, value.isFinite { return value }
            return nil
        }

        let digits = trimmed.filter { $0.isNumber || $0 == "." || $0 == "," }
        let normalized = digits.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0, value.isFinite else {
            return nil
        }
        return value
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter
    }()
}

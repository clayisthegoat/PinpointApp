import SwiftUI
import UIKit

enum PinpointAppearance {
    static let presets = ["Blue", "Purple", "Green", "Orange", "Red", "Pink", "Teal", "Indigo", "Mint", "Cyan", "Yellow", "Brown", "Graphite"]
    static func color(_ name: String) -> Color {
        switch name {
        case "Purple": return .purple
        case "Green": return .green
        case "Orange": return .orange
        case "Red": return .red
        case "Pink": return .pink
        case "Teal": return .teal
        case "Indigo": return .indigo
        case "Mint": return .mint
        case "Cyan": return .cyan
        case "Yellow": return .yellow
        case "Brown": return .brown
        case "Graphite": return .gray
        default:
            if name.hasPrefix("#"), name.count == 7, let rgb = UInt32(name.dropFirst(), radix: 16) {
                return Color(red: Double((rgb >> 16) & 255) / 255, green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255)
            }
            return .blue
        }
    }
    static func hex(_ color: Color) -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X", Int((min(max(r, 0), 1) * 255).rounded()), Int((min(max(g, 0), 1) * 255).rounded()), Int((min(max(b, 0), 1) * 255).rounded()))
    }
}

struct PinpointAccentPicker: View {
    @Binding var accent: String
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabeledContent("Accent color", value: accent.hasPrefix("#") ? "Custom" : accent)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(PinpointAppearance.presets, id: \.self) { name in
                    Button { accent = name } label: {
                        VStack(spacing: 5) {
                            Circle().fill(PinpointAppearance.color(name))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if accent == name {
                                        Image(systemName: "checkmark").font(.caption.bold())
                                            .foregroundStyle(.white).shadow(color: .black.opacity(0.6), radius: 2)
                                    }
                                }
                                .padding(3)
                                .overlay { Circle().strokeBorder(accent == name ? Color.primary : Color.clear, lineWidth: 2) }
                            Text(name).font(.caption2).foregroundStyle(.primary)
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(.plain)
                        .accessibilityAddTraits(accent == name ? .isSelected : [])
                }
            }
            ColorPicker("Custom color", selection: Binding(
                get: { PinpointAppearance.color(accent) },
                set: { if let hex = PinpointAppearance.hex($0) { accent = hex } }
            ), supportsOpacity: false)
            if accent.hasPrefix("#") { Text(accent).font(.caption.monospaced()).foregroundStyle(.secondary) }
        }.padding(.vertical, 6)
    }
}

struct PinpointShortcutButtonStyle: ButtonStyle {
    let accent: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(accent)
            .background(accent.opacity(configuration.isPressed ? 0.22 : 0.10), in: RoundedRectangle(cornerRadius: 17))
            .overlay { RoundedRectangle(cornerRadius: 17).strokeBorder(accent.opacity(0.22), lineWidth: 1) }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

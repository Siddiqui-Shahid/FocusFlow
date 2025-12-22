import SwiftUI
import UIKit

extension UIColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        // Support RGB (6) or ARGB/RGBA (8)
        let len = s.count
        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, a: UInt64 = 255
        guard len == 6 || len == 8 else { return nil }
        var hexValue: UInt64 = 0
        Scanner(string: s).scanHexInt64(&hexValue)
        if len == 6 {
            r = (hexValue & 0xFF0000) >> 16
            g = (hexValue & 0x00FF00) >> 8
            b = (hexValue & 0x0000FF)
        } else {
            // interpret as RRGGBBAA or AARRGGBB? We'll assume RRGGBBAA
            r = (hexValue & 0xFF000000) >> 24
            g = (hexValue & 0x00FF0000) >> 16
            b = (hexValue & 0x0000FF00) >> 8
            a = (hexValue & 0x000000FF)
        }
        self.init(red: CGFloat(r) / 255.0,
                  green: CGFloat(g) / 255.0,
                  blue: CGFloat(b) / 255.0,
                  alpha: CGFloat(a) / 255.0)
    }

    func toHex(includeAlpha: Bool = false) -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard self.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
        } else {
            return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }
    }
}

extension Color {
    init?(hex: String) {
        guard let ui = UIColor(hex: hex) else { return nil }
        self.init(uiColor: ui)
    }

    func toHex(includeAlpha: Bool = false) -> String? {
        let ui = UIColor(self)
        return ui.toHex(includeAlpha: includeAlpha)
    }
}

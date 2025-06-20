import SwiftUI
import CoreText

struct ColorUtils {
    static func hexToColor(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        let alpha = hexSanitized.count == 8 ? Double((rgb & 0xFF000000) >> 24) / 255.0 : 1.0
        
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension Font {
    static func nostalgic(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgic-Regular", size: size)
    }
    
    static func nostalgicCondensed(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgic-Condensed", size: size)
    }
    
    static func nostalgicSemiCondensed(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgic-SemiCond", size: size)
    }
    
    static func nostalgicExtraCondensed(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgic-ExtraCond", size: size)
    }
    
    static func nostalgicUltraCondensed(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgic-UltraCond", size: size)
    }
    
    static func nostalgicItalic(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgicItal-Reg", size: size)
    }
    
    static func nostalgicItalicCondensed(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgicItal-Cond", size: size)
    }
    
    static func nostalgicItalicSemiCondensed(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgicItal-SmCn", size: size)
    }
    
    static func nostalgicItalicUltraCondensed(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgicItal-UCn", size: size)
    }
    
    static func nostalgicItalicExtraCondensed(size: CGFloat) -> Font {
        return Font.custom("SeriouslyNostalgicItal-XCn", size: size)
    }
}

struct MealType: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String // SF Symbol name

    // Centralised list of available meal categories
    static let types: [MealType] = [
        MealType(title: "Breakfast", icon: "sunrise.fill"),
        MealType(title: "Lunch", icon: "fork.knife"),
        MealType(title: "Dinner", icon: "moon.stars.fill"),
        MealType(title: "Snack", icon: "cup.and.saucer.fill")
    ]
}

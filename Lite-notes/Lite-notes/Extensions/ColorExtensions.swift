import SwiftUI

extension Color {
    static var platformControlBackground: Color {
        #if os(macOS)
        return Color(.controlBackgroundColor)
        #else
        return Color(.secondarySystemBackground)
        #endif
    }
    
    static var platformTextBackground: Color {
        #if os(macOS)
        return Color(.textBackgroundColor)
        #else
        return Color(.secondarySystemBackground)
        #endif
    }
    
    static var platformBackground: Color {
        #if os(macOS)
        return Color(.windowBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
}
import SwiftUI

enum Theme {
    case light
    case dark
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .light
    
    func toggleTheme() {
        currentTheme = (currentTheme == .light) ? .dark : .light
    }
}

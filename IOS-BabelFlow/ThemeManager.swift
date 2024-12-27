import SwiftUI

class ThemeManager: ObservableObject {
    @Published private(set) var colorScheme: ColorScheme = .light
    
    @AppStorage("isDarkMode") private var isDarkMode = false {
        didSet {
            updateColorScheme()
        }
    }
    
    init() {
        updateColorScheme()
    }
    
    private func updateColorScheme() {
        colorScheme = isDarkMode ? .dark : .light
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
    
    func setTheme(_ isDark: Bool) {
        isDarkMode = isDark
    }
}

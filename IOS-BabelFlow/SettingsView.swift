import SwiftUI
import Services

struct SettingsView: View {
    @AppStorage("defaultSourceLanguage") private var defaultSourceLanguage = "Auto"
    @AppStorage("defaultTargetLanguage") private var defaultTargetLanguage = "English"
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var translationService: TranslationService
    @Binding var showAPIKeySettings: Bool
    
    let languages = ["Auto", "English", "Chinese", "Spanish", "French", "German", "Japanese", "Korean"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Languages")) {
                    Picker("Source Language", selection: $defaultSourceLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    
                    Picker("Target Language", selection: $defaultTargetLanguage) {
                        ForEach(languages.filter { $0 != "Auto" }, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                }
                
                Section {
                    Button("API Key Settings") {
                        showAPIKeySettings = true
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(showAPIKeySettings: .constant(false))
        .environmentObject(TranslationService())
}

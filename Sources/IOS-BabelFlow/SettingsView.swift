import SwiftUI

@available(macOS 12.0, *)
public struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("defaultSourceLanguage") private var sourceLanguage = "Auto"
    @AppStorage("defaultTargetLanguage") private var targetLanguage = "English"
    
    private let languages = ["Auto", "English", "Chinese", "Japanese", "Korean", "Spanish", "French", "German"]
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Languages")) {
                    Picker("Source Language", selection: $sourceLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    
                    Picker("Target Language", selection: $targetLanguage) {
                        ForEach(languages.filter { $0 != "Auto" }, id: \.self) { language in
                            Text(language).tag(language)
                        }
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

#if DEBUG
@available(macOS 12.0, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif

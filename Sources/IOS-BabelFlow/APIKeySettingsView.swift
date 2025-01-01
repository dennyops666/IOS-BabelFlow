import SwiftUI

@available(macOS 11.0, *)
public struct APIKeySettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var translationService: TranslationService
    @State private var apiKey: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    public init(translationService: TranslationService) {
        self.translationService = translationService
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Key")) {
                    SecureField("Enter API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onAppear {
                            apiKey = translationService.apiKey
                        }
                }
                
                Section {
                    Button("Save") {
                        do {
                            try translationService.saveAPIKey(apiKey)
                            alertTitle = "Success"
                            alertMessage = "API key saved successfully"
                            showAlert = true
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            alertTitle = "Error"
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
            .navigationTitle("API Key Settings")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#if DEBUG
@available(macOS 11.0, *)
struct APIKeySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        APIKeySettingsView(translationService: TranslationService())
    }
}
#endif

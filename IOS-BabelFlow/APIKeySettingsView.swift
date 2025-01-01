import SwiftUI
import Services

struct APIKeySettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var translationService: TranslationService
    @State private var apiKey: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                SecureField("Enter API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Save API Key") {
                    saveAPIKey()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                if translationService.useCustomAPIKey {
                    Button("Clear API Key", role: .destructive) {
                        clearAPIKey()
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("API Key Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if alertTitle == "Success" {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadAPIKey()
            }
        }
    }
    
    private func saveAPIKey() {
        do {
            try translationService.saveAPIKey(apiKey)
            alertTitle = "Success"
            alertMessage = "API key saved successfully"
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func loadAPIKey() {
        apiKey = translationService.apiKey
    }
    
    private func clearAPIKey() {
        do {
            try translationService.saveAPIKey("")
            apiKey = ""
            alertTitle = "Success"
            alertMessage = "API key cleared successfully"
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    APIKeySettingsView()
        .environmentObject(TranslationService())
}

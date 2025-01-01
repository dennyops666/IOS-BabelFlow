import SwiftUI

@available(macOS 12.0, *)
@main
struct IOS_BabelFlowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#if DEBUG
@available(macOS 12.0, *)
struct IOS_BabelFlowApp_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

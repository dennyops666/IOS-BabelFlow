import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("BabelFlow")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    LaunchScreen()
}

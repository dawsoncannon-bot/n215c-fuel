import SwiftUI

struct TestView: View {
    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()
            Text("HELLO")
                .font(.system(size: 60))
                .foregroundColor(.white)
        }
    }
}

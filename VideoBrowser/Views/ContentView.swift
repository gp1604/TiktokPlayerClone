import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ExploreView()
                .navigationTitle("Explore")
                .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
} 
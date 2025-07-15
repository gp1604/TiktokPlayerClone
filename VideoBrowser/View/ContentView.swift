import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskMonitor: TaskMonitor
    
    var body: some View {
        NavigationView {
            ZStack {
                ExploreView()
                    .navigationTitle("Explore")
                    .navigationBarTitleDisplayMode(.large)
                
                // Debug task monitor (only show in debug builds)
                #if DEBUG
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        TaskMonitorView(taskMonitor: taskMonitor)
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                    }
                }
                #endif
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskMonitor())
} 
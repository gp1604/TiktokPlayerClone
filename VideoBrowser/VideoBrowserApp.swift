import SwiftUI

@main
struct VideoBrowserApp: App {
    @StateObject private var taskManager = AsyncTaskManager()
    @StateObject private var taskMonitor = TaskMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskManager)
                .environmentObject(taskMonitor)
                .onAppear {
                    taskMonitor.startMonitoring(taskManager: taskManager)
                }
                .onDisappear {
                    taskMonitor.stopMonitoring()
                }
        }
    }
} 
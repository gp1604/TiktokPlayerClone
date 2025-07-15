import Foundation
import SwiftUI

/// A debugging utility to monitor active tasks and help identify request accumulation
class TaskMonitor: ObservableObject {
    @Published var activeTaskCount: Int = 0
    @Published var warningThreshold: Int = 10
    @Published var isWarningActive: Bool = false
    
    private var taskManager: AsyncTaskManager?
    private var timer: Timer?
    
    func startMonitoring(taskManager: AsyncTaskManager) {
        self.taskManager = taskManager
        
        // Monitor task count every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTaskCount()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        taskManager = nil
    }
    
    private func updateTaskCount() {
        guard let taskManager = taskManager else { return }
        
        let count = taskManager.activeTaskCount
        DispatchQueue.main.async {
            self.activeTaskCount = count
            self.isWarningActive = count >= self.warningThreshold
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

/// A SwiftUI view that displays task monitoring information
struct TaskMonitorView: View {
    @ObservedObject var taskMonitor: TaskMonitor
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(taskMonitor.isWarningActive ? .red : .green)
                
                Text("Active Tasks: \(taskMonitor.activeTaskCount)")
                    .font(.caption)
                    .foregroundColor(taskMonitor.isWarningActive ? .red : .primary)
                
                if taskMonitor.isWarningActive {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }
            
            if taskMonitor.isWarningActive {
                Text("Warning: Too many active tasks!")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
} 
import Foundation
import SwiftUI

/// A utility class to manage async operations and prevent accumulation of requests
class AsyncTaskManager: ObservableObject {
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private let queue = DispatchQueue(label: "com.videobrowser.asynctaskmanager", qos: .userInitiated)
    
    /// Executes an async operation with proper cancellation management
    /// - Parameters:
    ///   - id: Unique identifier for the task
    ///   - operation: The async operation to execute
    func executeTask(id: String, operation: @escaping () async -> Void) {
        queue.async { [weak self] in
            // Cancel existing task with same ID
            self?.cancelTask(id: id)
            
            // Create new task
            let task = Task {
                await operation()
            }
            
            self?.activeTasks[id] = task
        }
    }
    
    /// Cancels a specific task by ID
    /// - Parameter id: The task identifier
    func cancelTask(id: String) {
        queue.async { [weak self] in
            if let task = self?.activeTasks[id] {
                task.cancel()
                self?.activeTasks.removeValue(forKey: id)
            }
        }
    }
    
    /// Cancels all active tasks
    func cancelAllTasks() {
        queue.async { [weak self] in
            self?.activeTasks.values.forEach { $0.cancel() }
            self?.activeTasks.removeAll()
        }
    }
    
    /// Checks if a task is still active
    /// - Parameter id: The task identifier
    /// - Returns: True if the task is active, false otherwise
    func isTaskActive(id: String) -> Bool {
        queue.sync {
            return activeTasks[id] != nil
        }
    }
    
    /// Gets the number of active tasks
    var activeTaskCount: Int {
        queue.sync {
            return activeTasks.count
        }
    }
    
    deinit {
        cancelAllTasks()
    }
}

/// A SwiftUI view modifier that automatically manages async tasks
struct AsyncTaskModifier: ViewModifier {
    let taskManager: AsyncTaskManager
    let taskId: String
    let operation: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                taskManager.executeTask(id: taskId, operation: operation)
            }
            .onDisappear {
                taskManager.cancelTask(id: taskId)
            }
    }
}

extension View {
    /// Adds async task management to a view
    /// - Parameters:
    ///   - taskManager: The task manager instance
    ///   - taskId: Unique identifier for the task
    ///   - operation: The async operation to execute
    /// - Returns: A view with async task management
    func asyncTask(
        taskManager: AsyncTaskManager,
        taskId: String,
        operation: @escaping () async -> Void
    ) -> some View {
        modifier(AsyncTaskModifier(
            taskManager: taskManager,
            taskId: taskId,
            operation: operation
        ))
    }
}
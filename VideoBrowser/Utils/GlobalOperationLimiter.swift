import Foundation
import SwiftUI

/// A global operation limiter that prevents too many concurrent operations
class GlobalOperationLimiter: ObservableObject {
    static let shared = GlobalOperationLimiter()
    
    private let maxConcurrentOperations = 5
    private let semaphore = DispatchSemaphore(value: 5)
    private let queue = DispatchQueue(label: "com.videobrowser.globaloperationlimiter", qos: .userInitiated)
    private var activeOperations: Set<String> = []
    
    private init() {}
    
    /// Executes an operation with global concurrency control
    /// - Parameters:
    ///   - id: Unique identifier for the operation
    ///   - operation: The operation to execute
    ///   - completion: Completion handler
    func executeOperation<T>(
        id: String,
        operation: @escaping () async throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Check if operation is already active
            if self.activeOperations.contains(id) {
                completion(.failure(OperationError.duplicateOperation))
                return
            }
            
            // Wait for semaphore
            self.semaphore.wait()
            self.activeOperations.insert(id)
            
            // Execute operation
            Task {
                do {
                    let result = try await operation()
                    await MainActor.run {
                        completion(.success(result))
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(error))
                    }
                }
                
                // Release semaphore
                self.queue.async {
                    self.activeOperations.remove(id)
                    self.semaphore.signal()
                }
            }
        }
    }
    
    /// Cancels an operation
    /// - Parameter id: The operation identifier
    func cancelOperation(id: String) {
        queue.async { [weak self] in
            self?.activeOperations.remove(id)
        }
    }
    
    /// Gets the number of active operations
    var activeOperationCount: Int {
        queue.sync {
            return activeOperations.count
        }
    }
    
    /// Gets the available slots for new operations
    var availableSlots: Int {
        return maxConcurrentOperations - activeOperationCount
    }
    
    /// Checks if an operation can be started
    func canStartOperation() -> Bool {
        return availableSlots > 0
    }
}

/// Custom error types for operation management
enum OperationError: Error, LocalizedError {
    case duplicateOperation
    case tooManyOperations
    case operationCancelled
    
    var errorDescription: String? {
        switch self {
        case .duplicateOperation:
            return "Operation is already in progress"
        case .tooManyOperations:
            return "Too many concurrent operations"
        case .operationCancelled:
            return "Operation was cancelled"
        }
    }
}

/// A SwiftUI view modifier that applies global operation limiting
struct GlobalOperationModifier: ViewModifier {
    let operationId: String
    let operation: () async throws -> Void
    let onError: (Error) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                guard GlobalOperationLimiter.shared.canStartOperation() else {
                    onError(OperationError.tooManyOperations)
                    return
                }
                
                GlobalOperationLimiter.shared.executeOperation(
                    id: operationId,
                    operation: operation
                ) { result in
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        onError(error)
                    }
                }
            }
            .onDisappear {
                GlobalOperationLimiter.shared.cancelOperation(id: operationId)
            }
    }
}

extension View {
    /// Adds global operation limiting to a view
    /// - Parameters:
    ///   - operationId: Unique identifier for the operation
    ///   - operation: The operation to execute
    ///   - onError: Error handler
    /// - Returns: A view with global operation limiting
    func globalOperation(
        operationId: String,
        operation: @escaping () async throws -> Void,
        onError: @escaping (Error) -> Void
    ) -> some View {
        modifier(GlobalOperationModifier(
            operationId: operationId,
            operation: operation,
            onError: onError
        ))
    }
} 
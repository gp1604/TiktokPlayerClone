import UIKit
import AVFoundation
import Foundation

/// A centralized thumbnail generator that limits concurrent operations
class ThumbnailGenerator: ObservableObject {
    static let shared = ThumbnailGenerator()
    
    private let maxConcurrentOperations = 3
    private let operationQueue = DispatchQueue(label: "com.videobrowser.thumbnailgenerator", qos: .userInitiated)
    private var activeOperations: [String: Task<Void, Never>] = [:]
    private let semaphore = DispatchSemaphore(value: 3)
    
    private init() {}
    
    /// Generates a thumbnail for a video URL with proper concurrency control
    /// - Parameters:
    ///   - url: The video URL
    ///   - size: The desired thumbnail size
    ///   - completion: Completion handler with the generated thumbnail or error
    func generateThumbnail(
        for url: URL,
        size: CGSize = CGSize(width: 120, height: 200),
        completion: @escaping (UIImage?) -> Void
    ) {
        let urlString = url.absoluteString
        
        // Check cache first
        if let cachedImage = ThumbnailCache.shared.getThumbnail(for: url) {
            completion(cachedImage)
            return
        }
        
        // Cancel existing operation for this URL
        cancelOperation(for: urlString)
        
        // Create new operation
        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.generateThumbnailAsync(url: url, size: size, completion: completion)
        }
        
        activeOperations[urlString] = task
    }
    
    private func generateThumbnailAsync(
        url: URL,
        size: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) async {
        let urlString = url.absoluteString
        
        // Wait for semaphore (limit concurrent operations)
        await withCheckedContinuation { continuation in
            operationQueue.async {
                self.semaphore.wait()
                continuation.resume()
            }
        }
        
        defer {
            // Release semaphore
            operationQueue.async {
                self.semaphore.signal()
            }
        }
        
        // Check if task was cancelled
        guard !Task.isCancelled else {
            await MainActor.run {
                completion(nil)
            }
            return
        }
        
        do {
            // Create asset on background thread using AssetLoader
            let asset = try await AssetLoader.loadAsset(from: url)
            
            // Check if task was cancelled after loading
            guard !Task.isCancelled else {
                await MainActor.run {
                    completion(nil)
                }
                return
            }
            
            // Create image generator on background thread
            let assetImgGenerate = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            assetImgGenerate.maximumSize = size
            assetImgGenerate.requestedTimeToleranceBefore = .zero
            assetImgGenerate.requestedTimeToleranceAfter = .zero
            
            let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
            
            // Check if task was cancelled before generating
            guard !Task.isCancelled else {
                await MainActor.run {
                    completion(nil)
                }
                return
            }
            
            let result = try await withTimeout(seconds: 5) {
                try await assetImgGenerate.image(at: time)
            }
            
            // Check if task was cancelled after generating
            guard !Task.isCancelled else {
                await MainActor.run {
                    completion(nil)
                }
                return
            }
            
            let thumbnail = UIImage(cgImage: result.image)
            
            // Cache the thumbnail
            ThumbnailCache.shared.setThumbnail(thumbnail, for: url)
            
            // Remove from active operations
            await MainActor.run {
                self.activeOperations.removeValue(forKey: urlString)
                completion(thumbnail)
            }
            
        } catch {
            // Check if task was cancelled
            guard !Task.isCancelled else {
                await MainActor.run {
                    completion(nil)
                }
                return
            }
            
            print("Error generating thumbnail for \(url): \(error)")
            
            await MainActor.run {
                self.activeOperations.removeValue(forKey: urlString)
                completion(nil)
            }
        }
    }
    
    /// Cancels an operation for a specific URL
    /// - Parameter urlString: The URL string to cancel
    func cancelOperation(for urlString: String) {
        if let task = activeOperations[urlString] {
            task.cancel()
            activeOperations.removeValue(forKey: urlString)
        }
    }
    
    /// Cancels all active operations
    func cancelAllOperations() {
        activeOperations.values.forEach { $0.cancel() }
        activeOperations.removeAll()
    }
    
    /// Gets the number of active operations
    var activeOperationCount: Int {
        return activeOperations.count
    }
    
    deinit {
        cancelAllOperations()
    }
}

// Helper function for timeout with better cancellation support
private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw CancellationError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
} 
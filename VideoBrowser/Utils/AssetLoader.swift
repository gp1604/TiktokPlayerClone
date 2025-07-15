import AVFoundation
import Foundation

/// A utility class to handle AVAsset loading asynchronously
class AssetLoader {
    
    /// Loads an AVAsset asynchronously to prevent main thread blocking
    /// - Parameter url: The URL of the asset to load
    /// - Returns: A loaded AVAsset
    /// - Throws: An error if the asset cannot be loaded
    static func loadAsset(from url: URL) async throws -> AVAsset {
        let asset = AVAsset(url: url)
        
        // Load essential properties asynchronously
        try await asset.load(.isReadable)
        
        return asset
    }
    
    /// Loads an AVAsset with specific properties asynchronously
    /// - Parameters:
    ///   - url: The URL of the asset to load
    ///   - propertyNames: The property names to load
    /// - Returns: A loaded AVAsset
    /// - Throws: An error if the asset cannot be loaded
    static func loadAsset(from url: URL, propertyNames: [String]) async throws -> AVAsset {
        let asset = AVAsset(url: url)
        
        // Load specified properties asynchronously
        for propertyName in propertyNames {
            try await asset.loadValues(forKeys: [propertyName])
        }
        
        return asset
    }
    
    /// Creates an AVPlayerItem asynchronously to prevent main thread blocking
    /// - Parameter url: The URL of the asset to load
    /// - Returns: A configured AVPlayerItem
    /// - Throws: An error if the player item cannot be created
    static func createPlayerItem(from url: URL) async throws -> AVPlayerItem {
        let asset = try await loadAsset(from: url)
        return AVPlayerItem(asset: asset)
    }
    
    /// Checks if an asset is readable without blocking the main thread
    /// - Parameter url: The URL of the asset to check
    /// - Returns: True if the asset is readable, false otherwise
    static func isAssetReadable(url: URL) async -> Bool {
        do {
            let asset = AVAsset(url: url)
            try await asset.load(.isReadable)
            return true
        } catch {
            return false
        }
    }
} 
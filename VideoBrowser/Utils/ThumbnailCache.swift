import UIKit

class ThumbnailCache {
    static let shared = ThumbnailCache()
    
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100 // Maximum number of thumbnails to cache
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    func getThumbnail(for url: URL) -> UIImage? {
        return cache.object(forKey: url.absoluteString as NSString)
    }
    
    func setThumbnail(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url.absoluteString as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
} 
import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let video: Video
    let index: Int
    let nodes: [Node]
    
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    @State private var showingVideoPlayer = false
    
    var body: some View {
        Button(action: {
            showingVideoPlayer = true
        }) {
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 200)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 200)
                        .cornerRadius(10)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            generateThumbnail()
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            VideoPlayerView(nodes: nodes, selectedIndex: index)
        }
    }
    
    private func generateThumbnail() {
        guard let url = URL(string: video.encodeURI) else { return }
        
        // Check cache first
        if let cachedImage = ThumbnailCache.shared.getThumbnail(for: url) {
            self.thumbnail = cachedImage
            self.isLoading = false
            return
        }
        
        let asset = AVAsset(url: url)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.maximumSize = CGSize(width: 120, height: 200)
        
        let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
        
        Task {
            do {
                let cgImage = try await assetImgGenerate.image(at: time)
                let thumbnail = UIImage(cgImage: cgImage)
                
                await MainActor.run {
                    self.thumbnail = thumbnail
                    self.isLoading = false
                }
                
                ThumbnailCache.shared.setThumbnail(thumbnail, for: url)
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("Error generating thumbnail: \(error)")
            }
        }
    }
}

#Preview {
    VideoThumbnailView(
        video: Video(encodeURI: "https://example.com/video.mp4"),
        index: 0,
        nodes: []
    )
} 
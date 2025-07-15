import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let video: Video
    let index: Int
    let nodes: [Node]
    
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    @State private var showingVideoPlayer = false
    @State private var thumbnailError = false
    @State private var isViewActive = false
    
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
                            Group {
                                if thumbnailError {
                                    Image(systemName: "video.slash")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
                
                if isLoading && !thumbnailError {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isViewActive = true
            generateThumbnail()
        }
        .onDisappear {
            isViewActive = false
            // Cancel thumbnail generation for this view
            if let url = URL(string: video.encodeURI) {
                ThumbnailGenerator.shared.cancelOperation(for: url.absoluteString)
            }
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            VideoPlayerView(nodes: nodes, selectedIndex: index)
        }
    }
    
    private func generateThumbnail() {
        guard let url = URL(string: video.encodeURI) else { 
            thumbnailError = true
            isLoading = false
            return 
        }
        
        // Check cache first
        if let cachedImage = ThumbnailCache.shared.getThumbnail(for: url) {
            self.thumbnail = cachedImage
            self.isLoading = false
            return
        }
        
        // Use centralized thumbnail generator
        ThumbnailGenerator.shared.generateThumbnail(for: url) { image in
            if self.isViewActive{
                DispatchQueue.main.async {
                    if let image = image {
                        self.thumbnail = image
                        self.isLoading = false
                        self.thumbnailError = false
                    } else {
                        self.isLoading = false
                        self.thumbnailError = true
                    }
                }
            } else {
                return
            }
        }
    }
}


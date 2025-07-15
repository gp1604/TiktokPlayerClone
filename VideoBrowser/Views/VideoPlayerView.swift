import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let nodes: [Node]
    let selectedIndex: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var timeObserver: Any?
    
    init(nodes: [Node], selectedIndex: Int) {
        self.nodes = nodes
        self.selectedIndex = selectedIndex
        self._currentIndex = State(initialValue: selectedIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let player = player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                }
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                
                // Back button
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.x > threshold {
                        // Swipe right - go to previous video
                        if currentIndex > 0 {
                            currentIndex -= 1
                            loadVideo(at: currentIndex)
                        }
                    } else if value.translation.x < -threshold {
                        // Swipe left - go to next video
                        if currentIndex < nodes.count - 1 {
                            currentIndex += 1
                            loadVideo(at: currentIndex)
                        }
                    }
                }
        )
        .onAppear {
            loadVideo(at: currentIndex)
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private func loadVideo(at index: Int) {
        guard index >= 0 && index < nodes.count else { return }
        
        // Clean up previous player
        cleanupPlayer()
        
        isLoading = true
        let videoURL = nodes[index].video.encodeURI
        
        guard let url = URL(string: videoURL) else {
            isLoading = false
            return
        }
        
        let newPlayer = AVPlayer(url: url)
        
        // Add periodic time observer to check if video is ready
        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { _ in
            if newPlayer.currentItem?.status == .readyToPlay &&
               newPlayer.currentItem?.isPlaybackLikelyToKeepUp == true {
                isLoading = false
            }
        }
        
        self.player = newPlayer
    }
    
    private func cleanupPlayer() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player?.pause()
        player = nil
    }
}

#Preview {
    VideoPlayerView(
        nodes: [Node(video: Video(encodeURI: "https://example.com/video.mp4"))],
        selectedIndex: 0
    )
} 
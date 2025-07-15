import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let nodes: [Node]
    let selectedIndex: Int
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerManager = VideoPlayerManager()
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var screenHeight: CGFloat = 0
    
    init(nodes: [Node], selectedIndex: Int) {
        self.nodes = nodes
        self.selectedIndex = selectedIndex
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Video stack with vertical scroll
                VStack(spacing: 0) {
                    ForEach(Array(nodes.enumerated()), id: \.offset) { index, node in
                        VideoPlayerCell(
                            videoURL: node.video.encodeURI,
                            isActive: index == playerManager.currentIndex,
                            onVideoReady: {
                                if index == playerManager.currentIndex {
                                    playerManager.isLoading = false
                                }
                            },
                            onVideoError: { error in
                                if index == playerManager.currentIndex {
                                    playerManager.showError(error)
                                }
                            }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .offset(y: -CGFloat(playerManager.currentIndex) * geometry.size.height + dragOffset)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: playerManager.currentIndex)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
                
                // Loading indicator
                if playerManager.isLoading && !playerManager.playerError {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading video...")
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                }
                
                // Error state
                if playerManager.playerError {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("Video Error")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text(playerManager.errorMessage)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        Button("Retry") {
                            playerManager.loadVideo(url: nodes[playerManager.currentIndex].video.encodeURI)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
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
                
                // Video progress indicator
                VStack {
                    Spacer()
                    HStack {
                        ForEach(0..<nodes.count, id: \.self) { index in
                            Rectangle()
                                .fill(index == playerManager.currentIndex ? Color.white : Color.white.opacity(0.3))
                                .frame(height: 2)
                                .animation(.easeInOut(duration: 0.3), value: playerManager.currentIndex)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .onAppear {
                screenHeight = geometry.size.height
            }
        }
        .gesture(
            DragGesture()
                .onChanged { drag in
                    isDragging = true
                    dragOffset = drag.translation.height
                }
                .onEnded { drag in
                    isDragging = false
                    let threshold = screenHeight * 0.3
                    
                    if abs(drag.translation.height) > threshold {
                        if drag.translation.height > 0 && playerManager.currentIndex > 0 {
                            // Swipe down - go to previous video
                            withAnimation(.easeInOut(duration: 0.3)) {
                                playerManager.currentIndex -= 1
                            }
                        } else if drag.translation.height < 0 && playerManager.currentIndex < nodes.count - 1 {
                            // Swipe up - go to next video
                            withAnimation(.easeInOut(duration: 0.3)) {
                                playerManager.currentIndex += 1
                            }
                        }
                    }
                    
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
        )
        .onAppear {
            playerManager.currentIndex = selectedIndex
        }
        .onDisappear {
            playerManager.cleanup()
        }
    }
}

struct VideoPlayerCell: View {
    let videoURL: String
    let isActive: Bool
    let onVideoReady: () -> Void
    let onVideoError: (String) -> Void
    
    @StateObject private var playerManager = VideoPlayerManager()
    
    var body: some View {
        ZStack {
            Color.black
            
            if let player = playerManager.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        if isActive {
                            player.play()
                        }
                    }
                    .onDisappear {
                        player.pause()
                    }
            }
        }
        .onAppear {
            playerManager.loadVideo(url: videoURL)
        }
        .onDisappear {
            playerManager.cleanup()
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                playerManager.player?.play()
            } else {
                playerManager.player?.pause()
            }
        }
        .onReceive(playerManager.$isLoading) { loading in
            if !loading && isActive {
                onVideoReady()
            }
        }
        .onReceive(playerManager.$playerError) { error in
            if error && isActive {
                onVideoError(playerManager.errorMessage)
            }
        }
    }
}

class VideoPlayerManager: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var playerError = false
    @Published var errorMessage = ""
    @Published var currentIndex = 0
    
    private var timeObserver: Any?
    private var loadingTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var isActive = false
    
    func loadVideo(url: String) {
        cleanup()
        
        isLoading = true
        playerError = false
        errorMessage = ""
        isActive = true
        
        guard let videoURL = URL(string: url) else {
            showError("Invalid video URL")
            return
        }
        
        // Load video asynchronously to avoid main thread blocking
        loadingTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // Create player item asynchronously using AssetLoader
                let playerItem = try await AssetLoader.createPlayerItem(from: videoURL)
                
                // Check if task was cancelled
                guard !Task.isCancelled && self.isActive else { return }
                
                await MainActor.run {
                    guard self.isActive else { return }
                    
                    // Create player on main thread
                    let newPlayer = AVPlayer(playerItem: playerItem)
                    
                    // Add observers
                    playerItem.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
                    playerItem.addObserver(self, forKeyPath: "error", options: [.new], context: nil)
                    
                    // Add periodic time observer
                    self.timeObserver = newPlayer.addPeriodicTimeObserver(
                        forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
                        queue: .main
                    ) { [weak self] _ in
                        guard let self = self, self.isActive else { return }
                        
                        if newPlayer.currentItem?.status == .readyToPlay &&
                           newPlayer.currentItem?.isPlaybackLikelyToKeepUp == true {
                            DispatchQueue.main.async {
                                if self.isActive {
                                    self.isLoading = false
                                }
                            }
                        }
                    }
                    
                    self.player = newPlayer
                }
                
                // Set timeout with cancellation support
                self.timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(15 * 1_000_000_000))
                    
                    await MainActor.run {
                        if self.isLoading && self.isActive {
                            self.showError("Video loading timeout")
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    if self.isActive {
                        self.showError("Failed to load video: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func showError(_ message: String) {
        guard isActive else { return }
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.playerError = true
            self.errorMessage = message
        }
    }
    
    func cleanup() {
        isActive = false
        
        // Cancel timeout task
        timeoutTask?.cancel()
        timeoutTask = nil
        
        // Cancel loading task
        loadingTask?.cancel()
        loadingTask = nil
        
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        // Remove observers
        player?.currentItem?.removeObserver(self, forKeyPath: "status")
        player?.currentItem?.removeObserver(self, forKeyPath: "error")
        
        player?.pause()
        player = nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard isActive else { return }
        
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                switch playerItem.status {
                case .failed:
                    showError("Failed to load video: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                case .readyToPlay:
                    DispatchQueue.main.async {
                        if self.isActive {
                            self.isLoading = false
                        }
                    }
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        } else if keyPath == "error" {
            if let playerItem = object as? AVPlayerItem, let error = playerItem.error {
                showError("Video error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    VideoPlayerView(
        nodes: [Node(video: Video(encodeURI: "https://example.com/video.mp4"))],
        selectedIndex: 0
    )
} 

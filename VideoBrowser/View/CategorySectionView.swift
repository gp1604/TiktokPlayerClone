import SwiftUI

struct CategorySectionView: View {
    let category: Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.title)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(category.nodes.enumerated()), id: \.offset) { index, node in
                        LazyThumbnailView(video: node.video, index: index, nodes: category.nodes)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 16)
    }
}

/// A lazy loading wrapper for VideoThumbnailView that only loads when visible
struct LazyThumbnailView: View {
    let video: Video
    let index: Int
    let nodes: [Node]
    
    @State private var isVisible = false
    
    var body: some View {
        Group {
            if isVisible {
                VideoThumbnailView(video: video, index: index, nodes: nodes)
            } else {
                // Placeholder while not visible
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
        }
        .onAppear {
            // Delay loading to prevent all thumbnails from loading at once
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

#Preview {
    CategorySectionView(category: Category(title: "Trending", nodes: []))
} 
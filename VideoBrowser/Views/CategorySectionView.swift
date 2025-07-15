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
                        VideoThumbnailView(video: node.video, index: index, nodes: category.nodes)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 16)
    }
}

#Preview {
    CategorySectionView(category: Category(title: "Trending", nodes: []))
} 
import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.categories.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(viewModel.categories, id: \.title) { category in
                        CategorySectionView(category: category)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            viewModel.getCategoriesData()
        }
        .onReceive(viewModel.$error) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        .alert("Error Occurred", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading videos...")
                .foregroundColor(.secondary)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No videos available")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Check your connection and try again")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ExploreView()
} 
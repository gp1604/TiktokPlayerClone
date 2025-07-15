# TikTok Clone with SwiftUI

A modern TikTok-style video browsing app built with SwiftUI, featuring smooth video playback, gesture-based navigation, and a clean, intuitive interface.

## Features

- **SwiftUI Architecture**: Modern declarative UI framework for better performance and maintainability
- **Video Categories**: Browse videos organized by categories (Trending, Must Watch, Newly Added, Popular)
- **Full-Screen Video Player**: Immersive video viewing experience with gesture controls
- **Swipe Navigation**: Swipe left/right to navigate between videos in a category
- **Thumbnail Generation**: Automatic video thumbnail generation with caching
- **Loading States**: Smooth loading indicators and error handling
- **Responsive Design**: Optimized for different screen sizes and orientations

## Architecture

### Views
- `ContentView`: Main app container with navigation
- `ExploreView`: Main video browsing interface
- `CategorySectionView`: Displays a category with horizontal scrolling videos
- `VideoThumbnailView`: Individual video thumbnail with tap-to-play
- `VideoPlayerView`: Full-screen video player with swipe navigation

### ViewModels
- `CategoryViewModel`: Manages video data loading and state using `@Published` properties

### Models
- `Category`: Represents a video category with title and nodes
- `Node`: Contains video information
- `Video`: Video metadata including playback URL

### Utilities
- `ThumbnailCache`: Efficient thumbnail caching system
- `Constants`: App-wide constants and configuration

## Key Improvements from UIKit Version

1. **Declarative UI**: SwiftUI's declarative syntax makes the UI code more readable and maintainable
2. **State Management**: `@StateObject` and `@Published` provide reactive state management
3. **Gesture Handling**: Native SwiftUI gesture recognition for video navigation
4. **Async/Await**: Modern concurrency for thumbnail generation
5. **Better Error Handling**: Comprehensive error states and user feedback
6. **Performance**: Improved memory management and caching

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository
2. Open `VideoBrowser.xcodeproj` in Xcode
3. Build and run on a device or simulator

## Usage

1. **Browse Videos**: Scroll through different video categories
2. **Play Videos**: Tap on any video thumbnail to start playback
3. **Navigate**: Swipe left/right in full-screen mode to change videos
4. **Close Player**: Tap the back button or swipe down to exit

## Data Source

The app uses a local JSON file (`assignment.json`) containing video URLs and category information. In a production app, this would typically come from a backend API.

## Future Enhancements

- User authentication and profiles
- Video upload functionality
- Comments and likes system
- Push notifications
- Offline video caching
- Advanced video filters and effects

## License

This project is for educational purposes. Please respect the original creator's work and use responsibly.


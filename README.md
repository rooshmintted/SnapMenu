# Menu Crimes 🍽️📱

A Snapchat-style camera-first iOS app for analyzing menu photos and sharing food experiences with friends.

## Features

### 🎥 Camera & Media
- **Photo & Video Capture**: Full-featured camera with photo and video recording capabilities
- **Media Preview**: Preview captured photos and videos before sharing
- **Gallery Access**: Browse and select media from photo library
- **Video Conversion**: Automatic MOV to MP4 conversion for Supabase compatibility
- **Duration Tracking**: Automatic video duration extraction and display

### 👥 Social Features
- **User Authentication**: Secure sign-up/sign-in with Supabase Auth
- **Friend System**: Add friends, send/accept friend requests
- **Contact Integration**: Find friends from your contacts
- **Multiple Friend Selection**: Send photos/videos to multiple friends at once
- **Media Sharing**: Share photos and videos with captions to friends
- **View Tracking**: Mark media as viewed, auto-hide viewed content

### 🔍 Analysis
- **Media Inbox**: View received photos and videos from friends
- **Unviewed Counter**: Badge showing number of unviewed items
- **Full-Screen Playback**: Tap to view photos/videos in detail
- **Clean Interface**: "All Caught Up!" when no unviewed content

### 🔐 Security & Privacy
- **Row Level Security**: Database-level access control
- **User Isolation**: Users can only see their own content and friend interactions
- **Secure Storage**: Media files stored in Supabase Storage with proper access controls

## Tech Stack

- **Frontend**: SwiftUI (iOS only)
- **Backend**: Supabase (Database, Auth, Storage)
- **State Management**: @Observable pattern
- **Media Processing**: AVFoundation for camera and video conversion
- **Architecture**: MVVM with manager classes

## Project Structure

```
Menu Crimes/
├── Menu_CrimesApp.swift          # App entry point
├── ContentView.swift             # Main tab interface
├── Models.swift                  # Data models and enums
├── Supabase.swift               # Supabase client configuration
│
├── Authentication/
│   ├── AuthManager.swift         # User authentication logic
│   └── AuthViews.swift          # Login/signup UI
│
├── Camera/
│   ├── CameraManager.swift       # Camera capture logic
│   ├── CameraView.swift         # Main camera interface
│   ├── CameraPreviewView.swift  # Camera preview component
│   ├── VideoPreviewView.swift   # Video preview and sharing
│   ├── ImagePicker.swift        # Photo library picker
│   └── PhotoGalleryManager.swift # Gallery management
│
├── Friends/
│   ├── FriendManager.swift       # Friend system logic
│   ├── FriendViews.swift        # Friend list and requests UI
│   ├── FriendSelectionView.swift # Friend selection for sharing
│   └── ProfileView.swift        # User profile management
│
├── Sharing/
│   ├── PhotoShareManager.swift   # Media upload and sharing
│   └── AnalysisView.swift       # Received media display
│
└── sql/
    ├── 04_shared_photos.sql     # Media sharing database schema
    └── 05_add_video_support.sql # Video support extensions
```

## Key Components

### AuthManager (@Observable)
- Handles user authentication with Supabase Auth
- Manages authentication state throughout the app
- Supports sign-up, sign-in, sign-out, and profile updates
- Automatic session checking and restoration

### FriendManager (@Observable)
- Manages friend relationships and requests
- Integrates with contacts for friend discovery
- Handles friend request sending, accepting, and rejection
- Loads and caches friend lists

### PhotoShareManager (@Observable)
- Handles media upload to Supabase Storage
- Manages sharing photos/videos with single or multiple friends
- Tracks sent and received media
- Provides unviewed media filtering
- Supports both photo and video formats

### CameraManager
- Controls camera functionality and permissions
- Handles photo capture and video recording
- Manages camera switching (front/back)
- Integrates with AVFoundation

## Database Schema

### Core Tables
- **profiles**: User profile information
- **friendships**: Friend relationships between users
- **friend_requests**: Pending friend requests with status tracking
- **shared_photos**: Shared media (photos/videos) with metadata

### Key Features
- Row Level Security (RLS) for data isolation
- Automatic timestamp tracking
- Foreign key relationships with cascade deletes
- Performance indexes for common queries
- Support for both photo and video media types

## Setup Instructions

### Prerequisites
- Xcode 15+
- iOS 17+ target device/simulator
- Supabase account and project

### Configuration
1. **Supabase Setup**:
   - Create a Supabase project
   - Run the SQL files in `/sql/` folder to set up database schema
   - Configure authentication settings
   - Set up storage bucket for media files

2. **App Configuration**:
   - Update `Supabase.swift` with your Supabase URL and anon key
   - Ensure camera permissions are configured in `Info.plist`
   - Build and run the project

### Environment Setup
```swift
// Supabase.swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```

## Usage

### Getting Started
1. **Sign Up**: Create an account with email and username
2. **Add Friends**: Search by username or import from contacts
3. **Capture Media**: Use the camera tab to take photos or record videos
4. **Share**: Select friends and send media with optional captions
5. **View**: Check the Analysis tab for received media from friends

### Key User Flows
- **Camera-First Experience**: Default to camera tab for Snapchat-style interaction
- **Multiple Friend Sharing**: Select multiple friends when sharing media
- **Inbox Experience**: View received media, automatically hide after viewing
- **Friend Management**: Add friends, manage requests, view friend profiles

## Architecture Patterns

### State Management
- **@Observable**: Used for all manager classes (AuthManager, FriendManager, etc.)
- **@State**: Local view state only
- **@Environment**: App-wide dependencies
- **@Binding**: Parent-child data flow for value types

### Data Flow
- Managers handle business logic and API calls
- Views observe managers for state changes
- Unidirectional data flow with reactive UI updates
- Proper error handling and loading states

### Code Organization
- **Manager Classes**: Business logic and API integration
- **View Components**: UI-only logic with manager dependencies
- **Models**: Data structures with Codable conformance
- **Extensions**: Utility functions and view modifiers

## Recent Updates

### Video Support
- ✅ Full video recording and sharing functionality
- ✅ Video preview with playback controls
- ✅ MOV to MP4 conversion for Supabase compatibility
- ✅ Video duration tracking and display
- ✅ Unified media sharing interface for photos and videos

### Multiple Friend Selection
- ✅ Select multiple friends when sharing media
- ✅ Efficient media upload (upload once, share with multiple)
- ✅ Dynamic UI showing selection count
- ✅ Batch database operations for performance

### Code Quality Improvements
- ✅ Eliminated code duplication between photo and video sharing
- ✅ Unified FriendSelectionView for all media types
- ✅ Enhanced error handling and debug logging
- ✅ Proper state management with @Observable pattern

## Development Guidelines

### Code Rules Applied
- **Debug Logging**: Comprehensive logging throughout the app for easier debugging
- **Code Comments**: Detailed comments explaining complex logic
- **No Duplication**: Unified components where possible (e.g., FriendSelectionView)
- **Simple Solutions**: Prefer straightforward implementations
- **Clean Organization**: Keep files under 200-300 lines, logical separation

### Performance Considerations
- Lazy loading for media lists
- Efficient database queries with proper indexing
- Image/video compression for storage optimization
- Cached friend lists and user profiles

## Contributing

When making changes:
1. Follow the established @Observable pattern for state management
2. Add comprehensive debug logging for new features
3. Ensure proper error handling in all async operations
4. Test with multiple users for social features
5. Maintain unified UI patterns across photo and video features

## Future Enhancements

- 🎯 AI-powered menu analysis and recommendations
- 📊 Advanced analytics with TelemetryDeck integration
- 💰 Monetization features with RevenueCat
- 🔔 Push notifications for friend requests and new media
- 🎨 Advanced media editing capabilities
- 🌐 Social discovery and restaurant integration

---

**Menu Crimes** - Where food photography meets social networking! 🍽️📸

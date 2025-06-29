# Menu Crimes - AI-Powered Menu Intelligence & Social Food Discovery 🍽️🤖

**Building the worlds knowledge graph for menus one photo at a time**

Ask MrMenu is a comprehensive iOS app that uses cutting-edge AI technology with rich search to analyze restaurant menus and discover culinary insights. Think "Perplexity AI for restaurants".

## 🌟 Core Features

### 🧠 AI-Powered Menu Analysis
- **Intelligent Menu Scanning**: Advanced OCR with Apple Vision Framework for precise text extraction
- **Profit Margin Analysis**: AI calculates estimated food costs and profit margins for each dish
- **Smart Ingredient Detection**: Identifies ingredients for better search and dietary filtering
- **Menu Embedding System**: RAG-powered vector database for intelligent menu search
- **Parallel Processing**: Analysis and embedding run simultaneously for efficiency

### 🔍 Premium AI Search ("Menu AI")
- **Natural Language Queries**: Ask complex questions like "Which restaurants write their menu like poetry?"
- **Contextual Understanding**: Interprets emotional tone, cooking techniques, and culinary styles
- **Source Attribution**: Shows exactly which menus and dishes inform each answer
- **Perplexity-Style Interface**: Professional chat experience with rotating example questions
- **Vector Search**: Powered by Pinecone and OpenAI for semantic menu understanding
- **RAG Database Integration**: Your menu uploads enhance search quality for everyone

### 📸 Advanced Camera & Media System
- **Professional Camera Interface**: Optimized for menu photography with preview matching
- **Photo & Video Support**: Capture both images and videos with unified sharing
- **Gallery Integration**: Select existing media with proper permission handling
- **Preview & Analysis**: Immediate menu analysis from captured photos
- **High-Quality Processing**: Professional image handling with aspect ratio matching
- **Format Conversion**: Automatic MOV to MP4 conversion for compatibility

### 📊 Profile Intelligence & Gamification
- **Upload Tracking**: Monitor how many menus you've contributed to the system
- **Achievement System**: Menu Detective badges and milestone tracking
- **Contribution Stats**: Track dishes analyzed and system contributions

## Tech Stack

### Core Technologies
- **Frontend**: SwiftUI (iOS 17+) with UIKit fallbacks
- **Backend**: Supabase (Database, Auth, Storage, Edge Functions)
- **AI/ML**: OpenAI GPT-4, Pinecone Vector Database, Apple Vision Framework
- **State Management**: @Observable pattern (iOS 17 Observation framework)
- **Media Processing**: AVFoundation, Vision Framework, Core Image
- **Architecture**: MVVM with specialized manager classes

### AI & Analysis Stack
- **Menu Analysis**: Custom Supabase Edge Functions with OpenAI integration
- **OCR Processing**: Apple Vision Framework for text recognition
- **Vector Embeddings**: Pinecone for semantic search capabilities
- **Natural Language Processing**: OpenAI for contextual understanding
- **Image Processing**: Vision Framework for coordinate detection and annotation

## Project Structure

```
Menu Crimes/
├── Menu_CrimesApp.swift              # App entry point with Core Data integration
├── ContentView.swift                 # Main tab interface (Camera, Search, Analysis, Profile)
├── Models.swift                      # Core data models, enums, and UserProfile
├── Supabase.swift                   # Supabase client configuration
│
├── AI & Analysis/
│   ├── MenuAnalysisManager.swift     # Core menu analysis orchestration
│   ├── MenuAnalysisResultView.swift  # Analysis results with interactive UI
│   ├── MenuAnnotationModels.swift    # Vision Framework coordinate integration
│   ├── MenuAnnotationView.swift      # Interactive annotation display
│   ├── MenuEmbeddingManager.swift    # RAG embedding system for search
│   ├── SearchAIManager.swift         # AI-powered natural language search
│   └── SearchView.swift             # Premium "Menu AI" search interface
│
├── Camera & Media/
│   ├── CameraView.swift             # Professional camera interface
│   ├── CameraPreviewView.swift      # Camera preview with controls
│   ├── PhotoGalleryManager.swift    # Gallery permissions and selection
│   ├── ImagePicker.swift            # Photo library integration
│   └── MediaConversionManager.swift  # MOV to MP4 conversion utilities
│
├── Authentication/
│   ├── AuthManager.swift             # Supabase Auth with profile management
│   ├── AuthViews.swift              # Login/signup UI with username system
│   └── ProfileView.swift            # Profile with stats, onboarding, sign out
│
├── Social Features/
│   ├── FriendManager.swift          # Friend requests, contacts, relationships
│   ├── FriendViews.swift            # Friend list, requests, detail views
│   ├── FriendSelectionView.swift    # Multi-friend selection for sharing
│   ├── PhotoShareManager.swift      # Analysis sharing with auto-hide
│   ├── AnalysisView.swift           # Received analysis viewer ("All Caught Up!")
│   ├── StoryManager.swift           # 24-hour ephemeral stories system
│   ├── StoryView.swift              # Story viewer with preloading
│   ├── PollManager.swift            # Menu polls creation and voting
│   └── PollView.swift               # Poll display and interaction
│
├── Onboarding/
│   └── OnboardingView.swift         # Enhanced 3-page onboarding flow
│       ├── MenuAnalysisIllustration  # AI analysis demo with profit margins
│       ├── AISearchIllustration      # Rotating questions with AI responses
│       └── ProfileIntelligenceIllustration # RAG impact and upload tracking
│
└── Supporting Files/
    ├── Extensions/                   # SwiftUI extensions and utilities
    ├── sql/                         # Complete database schema with RLS
    │   ├── tables.sql               # Core tables with foreign keys
    │   ├── friendship_system.sql    # Friend requests and relationships
    │   └── stories_rls_policies.sql # Storage policies for media
    └── Info.plist                  # Camera, contacts, photo permissions
```

## Key AI & Analysis Components

### MenuAnalysisManager (@Observable)
- **Core Analysis Orchestration**: Manages the complete menu analysis pipeline
- **Supabase Edge Function Integration**: Calls "anaylze-menu" function with OpenAI
- **Parallel Processing**: Runs analysis and embedding processes simultaneously
- **State Management**: Handles loading, success, and error states
- **Image Upload**: Manages Supabase Storage integration for menu photos

### MenuAnnotationModels & MenuAnnotationView
- **Vision Framework Integration**: Advanced OCR with precise coordinate detection
- **Interactive Annotations**: Clickable badges showing profit margins and cost breakdowns
- **Smart Text Matching**: Multiple matching strategies with confidence scoring
- **Visual Design**: Color-coded margin indicators with professional styling
- **Coordinate System**: Pixel-perfect positioning of annotations over detected text

### MenuEmbeddingManager (@Observable)
- **RAG Database Integration**: Processes menus for vector search capabilities
- **Intelligent Chunking**: Creates structured menu chunks by sections and dishes
- **Restaurant Integration**: Links all data to specific restaurants
- **Supabase Edge Function**: Calls "embed-menu" for vector processing
- **Parallel Processing**: Runs alongside analysis without blocking UI

### SearchAIManager (@Observable)
- **Natural Language Processing**: Handles complex restaurant queries
- **Supabase Edge Function**: Integrates with "search-menus" endpoint
- **Source Attribution**: Returns AI answers with specific menu sources
- **Error Handling**: Graceful fallbacks and user-friendly error messages
- **Real-time Search**: Async processing with loading states

### CameraManager & Media Processing
- **Menu-Optimized Capture**: Camera settings optimized for document photography
- **Preview Matching**: Ensures captured photos match preview exactly
- **Gallery Integration**: Seamless photo library access
- **Format Handling**: Automatic image processing and optimization

### AuthManager (@Observable)
- **Secure Authentication**: Supabase Auth with row-level security
- **User Profile Management**: Handles usernames, avatars, and preferences
- **Session Management**: Automatic token refresh and state persistence

## Database Schema

### Core Tables
- **profiles**: User profiles with username, avatar, website, and creation timestamps
- **shared_analyses**: Analysis sharing system with view tracking and auto-hide functionality
- **menu_embeddings**: Vector embeddings for RAG-powered semantic search

### Storage Buckets
- **menu_images**: Analysis images with public read access

### Key Database Features
- **Media Management**: Organized file structure with user-based folders
- **Performance Optimization**: Proper indexing on frequently queried columns

## Setup Instructions

### Prerequisites
- Xcode 15+ (iOS 17+ required for Vision Framework and @Observable pattern)
- Supabase account with project configured
- OpenAI API key for menu analysis and search
- Pinecone account for vector database

### Backend Configuration
1. **Supabase Setup**:
   - Create new Supabase project
   - Run SQL files in order: `tables.sql`, `friendship_system.sql`, `stories_rls_policies.sql`
   - Configure authentication settings (email confirmation optional)
   - Enable Row Level Security on all custom tables

2. **AI Services Setup**:
   - **OpenAI API**: Configure GPT-4 access for menu analysis and search
   - **Pinecone Database**: Set up vector database for menu embeddings
   - **Edge Function Environment**: Configure AI service credentials in Supabase
   - **Storage Policies**: Enable secure access with friend-based permissions

3. **App Configuration**:
   - Update `Supabase.swift` with your Supabase URL and anon key
   - Ensure camera permissions are configured in `Info.plist`
   - Verify iOS 17+ target for Vision Framework compatibility
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
2. **Analyze Menus**: Use the camera tab to capture restaurant menus
3. **AI Analysis**: Get instant profit margin analysis and dish recommendations
4. **Interactive Annotations**: Tap on colored badges to see detailed cost breakdowns
5. **Smart Search**: Use "Menu AI" to ask natural language questions about restaurants
6. **Analysis History**: Review your menu analysis history in the Analysis tab

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


## Contributing

When making changes:
1. Follow the established @Observable pattern for state management
2. Add comprehensive debug logging for new features
3. Ensure proper error handling in all async operations
4. Test with multiple users for social features
5. Maintain unified UI patterns across photo and video features

## Future Enhancements

### Planned AI Features
- 📈 **Trend Analysis**: Market insights and pricing recommendations

---

**Ask Mr Menu** - Building the worlds knowledge graph for menus one photo at a time! 🍽️📸

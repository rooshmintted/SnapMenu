# Ask Mr Menu - The Answer Engine for Your City’s Food Questions🍽️🤖

**AI-Powered Restaurant Menu Search + Analysis**

Ask Mr Menu is an iOS app that combines advanced AI technology with social features to analyze restaurant menus, discover hidden gems, and share culinary experiences. Think "Perplexity AI for restaurants" with sophisticated menu analysis capabilities.

## 🌟 Core Features

### 🧠 AI-Powered Menu Analysis
- **Intelligent Menu Scanning**: Advanced OCR and Vision Framework integration for precise text extraction
- **Profit Margin Analysis**: AI calculates estimated food costs and profit margins for each dish
- **Interactive Annotations**: Tap on colored badges to see detailed cost breakdowns and justifications
- **Smart Ingredient Detection**: Identifies ingredients for better search and dietary filtering
- **Menu Embedding System**: RAG-powered vector database for intelligent menu search
- **Restaurant Intelligence**: Comprehensive analysis with overall scoring and recommendations

### 🔍 Premium AI Search ("Menu AI")
- **Natural Language Queries**: Ask complex questions like "Which restaurants write their menu like poetry?"
- **Contextual Understanding**: Interprets emotional tone, cooking techniques, and culinary styles
- **Source Attribution**: Shows exactly which menus and dishes inform each answer
- **Perplexity-Style Interface**: Professional chat experience with rotating example questions
- **Vector Search**: Powered by Pinecone and OpenAI for semantic menu understanding

### 📸 Camera & Media Capabilities
- **Menu Photography**: Optimized camera interface for capturing menu photos
- **Gallery Integration**: Select existing photos for analysis
- **Video Support**: Record and share culinary experiences
- **Preview & Analysis**: Immediate menu analysis from captured photos
- **High-Quality Processing**: Professional image handling with aspect ratio matching

### 👥 Social & Sharing Features
- **User Authentication**: Secure Supabase Auth integration
- **Friend System**: Connect with other food enthusiasts
- **Multiple Sharing**: Send analyses to multiple friends simultaneously
- **Analysis History**: Track and revisit your menu discoveries
- **Social Discovery**: Find friends through contacts integration

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
├── Menu_CrimesApp.swift              # App entry point
├── ContentView.swift                 # Main tab interface (Camera, Search, Analysis, Profile)
├── Models.swift                      # Core data models and enums
├── Supabase.swift                   # Supabase client configuration
│
├── AI & Analysis/
│   ├── MenuAnalysisManager.swift     # Core menu analysis orchestration
│   ├── MenuAnalysisResultView.swift  # Analysis results with interactive UI
│   ├── MenuAnnotationModels.swift    # Vision Framework integration
│   ├── MenuAnnotationView.swift      # Interactive annotation display
│   ├── MenuEmbeddingManager.swift    # RAG embedding system
│   ├── SearchAIManager.swift         # AI-powered search functionality
│   └── SearchView.swift             # Premium "Menu AI" search interface
│
├── Camera & Media/
│   ├── CameraManager.swift           # Camera capture and permissions
│   ├── CameraView.swift             # Main camera interface
│   ├── CameraPreviewView.swift      # Camera preview component
│   ├── PhotoGalleryManager.swift    # Gallery selection and management
│   └── ImagePicker.swift            # Photo library integration
│
├── Authentication/
│   ├── AuthManager.swift             # Supabase Auth integration
│   ├── AuthViews.swift              # Login/signup UI components
│   └── ProfileView.swift            # User profile management
│
├── Social Features/
│   └── AnalysisView.swift           # Analysis history and sharing
│
├── Database/
│   └── sql/
│       └── tables.sql               # Database schema with RLS
│
└── Assets/
    ├── menu_items.json              # Sample data for development
    └── Sears-Menu-Breakfast-1.jpg   # Test menu image
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
   - Set up storage buckets: `analysis/`, `polls/`, and general media
   - Deploy edge functions: `anaylze-menu`, `embed-menu`, `search-menus`

2. **AI Service Configuration**:
   - **OpenAI API**: Configure API key in Supabase edge functions
   - **Pinecone Database**: Set up vector database for menu embeddings
   - **Edge Function Environment**: Configure AI service credentials
   - **Storage Policies**: Enable public read access for analysis images

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

### Core AI Features

#### Menu Analysis Workflow
1. **Capture Menu**: Take a photo of any restaurant menu
2. **Automatic Analysis**: AI analyzes each dish for profit margins and ingredients
3. **Interactive Annotations**: View color-coded margin indicators overlaid on menu items
4. **Detailed Breakdowns**: Tap any badge to see cost analysis and recommendations
5. **Smart Recommendations**: Get AI-powered suggestions for high-value dishes

#### Menu AI Search
1. **Natural Language Queries**: Ask questions like "Best seafood restaurants with good margins"
2. **Intelligent Responses**: Get AI-generated answers with source attribution
3. **Restaurant Discovery**: Find restaurants based on cuisine, price, or specific dishes
4. **Source Integration**: See actual menu excerpts supporting each recommendation

#### Advanced Features
- **Vision Framework OCR**: Precise text detection and coordinate mapping
- **Profit Margin Calculations**: Estimated food costs vs. menu prices
- **Interactive Annotations**: Clickable overlays with detailed justifications
- **RAG Database**: Vector embeddings for semantic menu search
- **Restaurant Context**: All analysis linked to specific restaurant locations

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

## Recent AI & Analysis Updates

### Menu Analysis System
- ✅ **OpenAI Integration**: Complete menu analysis with profit margin calculations
- ✅ **Vision Framework OCR**: Precise text detection and coordinate mapping
- ✅ **Interactive Annotations**: Clickable badges with detailed cost breakdowns
- ✅ **Smart Text Matching**: Multiple matching strategies with confidence scoring
- ✅ **Parallel Processing**: Analysis and embedding run simultaneously

### AI-Powered Search ("Menu AI")
- ✅ **Natural Language Processing**: Complex restaurant queries with context
- ✅ **RAG Database Integration**: Vector embeddings for semantic search
- ✅ **Source Attribution**: AI answers with specific menu sources
- ✅ **Perplexity-Style UI**: Premium search interface with professional design
- ✅ **Real-time Processing**: Async search with loading states

### Advanced Vision & Annotation Features
- ✅ **Coordinate System Fix**: Pixel-perfect annotation positioning
- ✅ **Restaurant Name Integration**: Auto-extraction and user input
- ✅ **Intelligent Chunking**: Menu sections with smart categorization
- ✅ **Interactive Overlays**: Touch-responsive margin indicators
- ✅ **Professional UI**: Color-coded visual hierarchy and typography

### Technical Infrastructure
- ✅ **Supabase Edge Functions**: Custom AI endpoints for analysis and search
- ✅ **Pinecone Vector Database**: Semantic similarity matching
- ✅ **Embedding Pipeline**: Automatic menu processing for search
- ✅ **Error Handling**: Comprehensive fallbacks and user feedback
- ✅ **Debug Logging**: Enhanced troubleshooting throughout AI pipeline

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

### Planned AI Features
- 📈 **Trend Analysis**: Market insights and pricing recommendations

---

**Ask Mr Menu** - Building the worlds knowledge graph for menus one photo at a time! 🍽️📸

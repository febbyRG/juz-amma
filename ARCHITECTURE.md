# Juz Amma - iOS App Architecture Documentation

## 📱 Project Overview

**App Name:** Juz Amma: Memorize Quran  
**Platform:** iOS 17+  
**Framework:** SwiftUI + SwiftData  
**Architecture Pattern:** MV (Model-View) with Service Layer  
**Code Size:** ~1,500 lines of Swift  
**Last Updated:** November 16, 2025

---

## 🏗️ Architecture Pattern

### Current Architecture: **MV + Service Layer**

Your app currently uses a **simplified MVVM** approach, which Apple now recommends for SwiftUI + SwiftData apps. Here's why:

```
Traditional iOS (UIKit):
Model ← ViewModel ← View
  ↓        ↓         ↓
Data    Logic    Display

Modern SwiftUI + SwiftData:
Model ← Service ← View
  ↓       ↓        ↓
Data   Logic   Display
```

### Why No Separate ViewModels?

✅ **SwiftData's `@Query` replaces ViewModels for data fetching**
- `@Query` automatically observes database changes
- No need for `@Published` properties or manual updates
- Views automatically refresh when data changes

✅ **SwiftUI's `@State` handles local UI state**
- Search text, filter toggles, sheet presentation
- No need for complex state management

✅ **Service Layer (`QuranDataService`) provides business logic**
- All CRUD operations centralized
- Data transformation and validation
- Reusable across multiple views

### Is This Best Practice?

**YES!** This is Apple's recommended approach for SwiftUI + SwiftData apps (WWDC 2023-2024):

1. **SwiftData handles data observation** → No need for `@ObservableObject` ViewModels
2. **`@Query` provides reactive data** → Views auto-update
3. **Service layer separates concerns** → Business logic isolated from views

---

## 📁 Project Structure

```
JuzAmma/
├── JuzAmmaApp.swift                    # App entry point + SwiftData setup
├── ContentView.swift                   # Root view with TabView
│
├── Models/                             # 🗂️ Data Models (SwiftData)
│   ├── Surah.swift                     # Surah + Ayah models (@Model)
│   └── AppSettings.swift               # User preferences (@Model)
│
├── Services/                           # ⚙️ Business Logic Layer
│   └── QuranDataService.swift          # CRUD operations, data loading
│
├── Features/                           # 🎨 Feature Modules (MVVM-lite)
│   ├── SurahList/
│   │   └── SurahListView.swift         # Main list screen
│   ├── SurahDetail/
│   │   └── SurahDetailView.swift       # Verse detail screen
│   └── Settings/
│       └── SettingsView.swift          # App settings screen
│
└── Resources/                          # 📦 Static Assets
    ├── juz_amma_data.json              # Quran data (564 verses, 208KB)
    └── Fonts/                          # Custom Arabic fonts
        ├── AmiriQuran.ttf              # Primary Quranic font (141KB)
        ├── AmiriQuranColored.ttf
        ├── Amiri-Regular.ttf
        └── Amiri-Bold.ttf
```

---

## 🧩 Architecture Components

### 1. Models Layer (`@Model` - SwiftData)

**Purpose:** Define data structure and persistence

#### `Surah.swift` (137 lines)
```swift
@Model
final class Surah {
    var number: Int                     // Surah number (78-114)
    var nameArabic: String              // Arabic name
    var nameTransliteration: String     // Romanized name
    var nameTranslation: String         // English meaning
    var ayahCount: Int                  // Verse count
    var revelation: String              // Makkah/Madinah
    
    // User tracking
    var isBookmarked: Bool
    var isMemorized: Bool
    var memorizedDate: Date?
    var lastAccessedDate: Date?
    var isNextToMemorize: Bool
    
    // Relationship
    @Relationship(deleteRule: .cascade) 
    var ayahs: [Ayah]?
}

@Model
final class Ayah {
    var number: Int
    var textArabic: String              // Uthmani script with diacritics
    var textTransliteration: String     // Romanized (empty for now)
    var translationEnglish: String      // Saheeh International
    var translationIndonesian: String   // Indonesian Ministry
    var isBookmarked: Bool
    var surah: Surah?                   // Parent reference
}
```

**Key Features:**
- ✅ SwiftData's `@Model` macro for automatic persistence
- ✅ Bidirectional relationship (Surah ↔ Ayah)
- ✅ Cascade delete (deleting Surah removes all Ayahs)
- ✅ Codable extensions for JSON import

#### `AppSettings.swift` (87 lines)
```swift
@Model
final class AppSettings {
    var id: String = "singleton"        // Singleton pattern
    var themeMode: ThemeMode            // Light/Dark/Auto
    var fontSizeMultiplier: Double      // 1.0 = default
    var showTransliteration: Bool
    var showEnglishTranslation: Bool
    var showIndonesianTranslation: Bool
    var notificationsEnabled: Bool
    var reminderTime: Date?
    var selectedQari: String            // For future audio feature
    var lastAppVersion: String
    var firstLaunchDate: Date
    var totalTimeSpent: TimeInterval
}

enum ThemeMode: String, Codable {
    case light, dark, auto
}
```

---

### 2. Service Layer (Business Logic)

**Purpose:** Encapsulate business operations, isolate data access logic

#### `QuranDataService.swift` (176 lines)

**Core Responsibilities:**
1. **Data Loading** - Import JSON into SwiftData
2. **CRUD Operations** - Create, Read, Update, Delete
3. **Business Logic** - Filtering, sorting, validation
4. **Settings Management** - Singleton pattern for app preferences

**Key Methods:**
```swift
class QuranDataService {
    private let modelContext: ModelContext
    
    // Data Loading
    func loadJuzAmmaData() async throws
    
    // Query Operations
    func getAllSurahs() throws -> [Surah]
    func getSurah(number: Int) throws -> Surah?
    func getBookmarkedSurahs() throws -> [Surah]
    func getMemorizedSurahs() throws -> [Surah]
    
    // User Actions
    func toggleBookmark(for surah: Surah) throws
    func toggleMemorization(for surah: Surah) throws
    func setNextToMemorize(_ surah: Surah) throws
    
    // Settings
    func getSettings() throws -> AppSettings
    func updateSettings(_ settings: AppSettings) throws
}
```

**Why Service Layer?**
- ✅ **Reusability** - Same logic across multiple views
- ✅ **Testability** - Easy to unit test business logic
- ✅ **Maintainability** - Changes in one place
- ✅ **Separation of Concerns** - Views don't know about persistence details

---

### 3. View Layer (SwiftUI)

**Purpose:** Display data, handle user interaction

#### `SurahListView.swift` (316 lines)

**Features:**
- List of 37 surahs from Juz Amma
- Search functionality (Arabic, transliteration, translation, number)
- Filter by bookmarked/memorized
- Progress tracking (X/37 memorized)
- "Next to Memorize" badge
- Stats dashboard

**Data Fetching:**
```swift
struct SurahListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Surah.number) private var surahs: [Surah]  // ✅ Auto-updates
    
    @State private var searchText = ""
    @State private var showBookmarksOnly = false
    
    private var filteredSurahs: [Surah] {
        // Filter logic here
    }
}
```

**Why No ViewModel?**
- `@Query` automatically observes database changes
- `filteredSurahs` computed property acts like ViewModel
- `@State` handles UI-specific state

#### `SurahDetailView.swift` (352 lines)

**Features:**
- Display all ayahs in a surah
- Arabic text with Amiri Quran font (proper diacritics)
- Toggle translations (English, Indonesian)
- Adjustable font size
- Bismillah view (except Surah 9)
- Bookmark individual ayahs

**State Management:**
```swift
struct SurahDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State var surah: Surah              // Passed from parent
    
    @State private var showEnglish = true
    @State private var fontSize: CGFloat = 20
    
    private var service: QuranDataService {
        QuranDataService(modelContext: modelContext)
    }
}
```

#### `SettingsView.swift` (158 lines)

**Features:**
- Theme selection (Light/Dark/Auto)
- Translation toggles
- Font size adjustment
- Notification settings (future)
- About section

---

### 4. App Entry Point

#### `JuzAmmaApp.swift`

**SwiftData Configuration:**
```swift
@main
struct JuzAmmaApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Surah.self, Ayah.self, AppSettings.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .task {
                    await loadInitialData()
                }
        }
    }
    
    @MainActor
    private func loadInitialData() async {
        let context = modelContainer.mainContext
        let service = QuranDataService(modelContext: context)
        try? await service.loadJuzAmmaData()
    }
}
```

---

## 🔄 Data Flow

### Example: User Bookmarks a Surah

```
1. USER ACTION
   └─> User taps bookmark icon in SurahListView
       
2. VIEW LAYER
   └─> Button action calls: service.toggleBookmark(for: surah)
       
3. SERVICE LAYER
   └─> QuranDataService.toggleBookmark()
       ├─> surah.isBookmarked.toggle()
       └─> modelContext.save()
       
4. SWIFTDATA (Automatic)
   └─> Database updated
       
5. @QUERY (Automatic)
   └─> Detects change in database
       
6. VIEW UPDATE (Automatic)
   └─> SurahListView re-renders with new bookmark state
```

**No manual refreshing needed!** SwiftData's observation system handles it.

---

## 🆚 MV vs MVVM Comparison

### Your Current Architecture (MV + Service)

```
┌─────────────────────────────────────┐
│           VIEW LAYER                │
│  (SurahListView, DetailView, etc)  │
│                                     │
│  • @Query for data observation      │
│  • @State for local UI state        │
│  • Computed properties for filters  │
└──────────────┬──────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│        SERVICE LAYER                 │
│     (QuranDataService)               │
│                                      │
│  • CRUD operations                   │
│  • Business logic                    │
│  • Data transformations              │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│         MODEL LAYER                  │
│  (Surah, Ayah, AppSettings)          │
│                                      │
│  • @Model for persistence            │
│  • SwiftData automatic sync          │
└──────────────────────────────────────┘
```

### Traditional MVVM (UIKit-style)

```
┌─────────────────────────────────────┐
│           VIEW LAYER                │
│      (SwiftUI Views)                │
└──────────────┬──────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│        VIEWMODEL LAYER               │
│   (ObservableObject + @Published)    │
│                                      │
│  • @Published properties             │
│  • Manual data fetching              │
│  • State management                  │
│  • Business logic                    │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│         MODEL LAYER                  │
│    (Data Models)                     │
└──────────────────────────────────────┘
```

### Why Your Approach is Better for SwiftData

| Aspect | MV + Service (Yours) | Traditional MVVM |
|--------|---------------------|------------------|
| **Data Observation** | `@Query` (automatic) | `@Published` (manual) |
| **Boilerplate** | Minimal | Heavy |
| **Database Sync** | Automatic via SwiftData | Manual fetching/refreshing |
| **State Management** | `@State` + computed properties | ViewModel properties |
| **Testability** | ✅ Test service layer | ✅ Test ViewModels |
| **Code Lines** | ~1,500 lines | ~2,000+ lines (est.) |

---

## ✅ Best Practices Implemented

### 1. Architecture
- ✅ Separation of concerns (Model, View, Service)
- ✅ Service layer for business logic
- ✅ Dependency injection (`modelContext` passed to service)
- ✅ SwiftData for automatic persistence and observation

### 2. SwiftUI
- ✅ `@Query` for reactive data fetching
- ✅ `@State` for view-local state
- ✅ `@Environment(\.modelContext)` for database access
- ✅ Computed properties for derived state

### 3. SwiftData
- ✅ `@Model` macro for models
- ✅ Relationships with cascade delete
- ✅ Singleton pattern for settings
- ✅ Proper error handling

### 4. Code Organization
- ✅ Feature-based folder structure
- ✅ Clear naming conventions
- ✅ Documentation comments
- ✅ Separation of Views into subviews

### 5. Data Management
- ✅ JSON-based initial data loading
- ✅ Offline-first architecture (no network dependency)
- ✅ Clean data (HTML removed, Unicode fixed)
- ✅ Automated data fetching script

---

## 🚀 When to Add ViewModels?

You should consider adding ViewModels if:

1. **Complex Business Logic in Views**
   - If computed properties become too complex
   - If views have 200+ lines of logic

2. **Network Calls with Loading States**
   - When adding audio streaming (Phase 2)
   - API calls for additional translations

3. **Heavy Computation**
   - Large-scale text processing
   - Image/audio processing

4. **Shared State Across Views**
   - Currently not needed (SwiftData handles this)

### Example ViewModel (if needed):

```swift
@Observable
class SurahListViewModel {
    private let service: QuranDataService
    
    var searchText = ""
    var showBookmarksOnly = false
    var isLoading = false
    
    init(service: QuranDataService) {
        self.service = service
    }
    
    var filteredSurahs: [Surah] {
        // Complex filtering logic here
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        // Heavy computation or API calls
    }
}
```

But for your current app, **this is unnecessary overhead**.

---

## 📊 Code Statistics

| Component | Files | Lines | Purpose |
|-----------|-------|-------|---------|
| **Models** | 2 | ~250 | Data structure + persistence |
| **Services** | 1 | ~180 | Business logic |
| **Views** | 4 | ~1,000 | UI + user interaction |
| **App Setup** | 2 | ~70 | Entry point + root view |
| **Total** | **9** | **~1,500** | Complete MVP |

### Features Implemented
- ✅ 37 Surahs with 564 verses
- ✅ Search (Arabic, transliteration, translation)
- ✅ Bookmark surahs and ayahs
- ✅ Track memorization progress
- ✅ Settings (theme, translations, font size)
- ✅ Offline-first (all data local)
- ✅ Custom Arabic font (Amiri Quran)
- ✅ Dual translations (English, Indonesian)

---

## 🎯 Architecture Recommendations

### ✅ Keep Current Structure For:
- All CRUD operations (via Service)
- Data fetching with `@Query`
- Simple UI state management
- Settings management

### 🔄 Consider Refactoring When:
1. **Adding Audio Playback** (Phase 2)
   - Create `AudioPlayerService`
   - Might need `AudioPlayerViewModel` for playback controls

2. **Network Features** (Future)
   - Create `NetworkService` for API calls
   - `DownloadManager` for audio caching

3. **Practice Mode** (Phase 2)
   - Create `PracticeViewModel` for quiz logic
   - Track scores, streak, performance

### Example Future Service Layer:
```
Services/
├── QuranDataService.swift      # Current
├── AudioPlayerService.swift    # Phase 2: Audio playback
├── NetworkService.swift        # Phase 3: Online features
├── NotificationService.swift   # Phase 2: Daily reminders
└── AnalyticsService.swift      # Phase 3: Usage tracking
```

---

## 🏆 Summary

**Your Architecture Score: 9/10**

### Strengths
✅ Modern SwiftUI + SwiftData approach  
✅ Clean separation of concerns  
✅ Service layer for business logic  
✅ Leverages framework features (`@Query`, `@Model`)  
✅ Minimal boilerplate  
✅ Easy to test and maintain  
✅ Follows Apple's WWDC 2023-2024 recommendations  

### Minor Improvements (Optional)
- Could add `@Observable` ViewModels for complex features in Phase 2
- Consider Repository pattern if adding network layer
- Add Dependency Injection container for larger scale

**Verdict:** Your architecture is **best practice for SwiftUI + SwiftData apps**. No need for traditional MVVM ViewModels. The Service Layer pattern you're using is the modern, recommended approach.

---

## 📚 References

- [Apple WWDC 2023: SwiftData](https://developer.apple.com/videos/play/wwdc2023/10187/)
- [Apple WWDC 2024: SwiftData Best Practices](https://developer.apple.com/videos/play/wwdc2024/10137/)
- [SwiftUI Architecture Patterns (Apple Docs)](https://developer.apple.com/documentation/swiftui/model-data)
- [The Composable Architecture (Point-Free)](https://www.pointfree.co/collections/composable-architecture)

---

**Last Updated:** November 16, 2025  
**App Version:** 1.0 MVP  
**Next Phase:** Audio Integration + Practice Mode

# Juz Amma - iOS App

<div align="center">

📖 **A Modern SwiftUI App for Memorizing Juz Amma**

*Made with ❤️ for Muslims worldwide*

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 🌟 Overview

**Juz Amma** is an open-source iOS app designed to help Muslims memorize and practice the 37 surahs of Juz Amma (Juz 30) - the last section of the Holy Quran. Built with modern SwiftUI and SwiftData, the app provides a clean, distraction-free interface for Quranic learning.

### ✨ Features

#### Phase 1 - MVP (Current)
- ✅ **Complete Juz Amma Collection** - All 37 surahs (78-114)
- ✅ **Arabic Text** - Beautiful, readable Arabic typography with RTL support
- ✅ **Transliteration** - Latin text for pronunciation help
- ✅ **Dual Translations** - English and Bahasa Indonesia
- ✅ **Smart Search** - Search by surah name, number, or translation
- ✅ **Bookmark System** - Quick access to favorite surahs
- ✅ **Memorization Tracker** - Track progress and set goals
- ✅ **Theme Support** - Light, Dark, and Auto modes
- ✅ **Offline-First** - All content works without internet
- ✅ **SwiftData Storage** - Modern local persistence

#### Coming Soon (Phase 2+)
- 🔜 Audio recitation with multiple Qaris
- 🔜 Practice mode for memorization
- 🔜 Progress statistics and streaks
- 🔜 Daily reminders
- 🔜 Cloud sync with authentication
- 🔜 Duas collection
- 🔜 Islamic articles and videos
- 🔜 Prayer times and Qibla direction

See [ROADMAP.md] for detailed feature plans.

---

## 📱 Screenshots

> Screenshots coming soon after UI refinement

---

## 🏗️ Architecture

### Tech Stack
- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Native persistence layer (iOS 17+)
- **MVVM Pattern** - Clean separation of concerns
- **Combine** - Reactive data flow
- **Swift Concurrency** - Async/await for data loading

### Project Structure
```
JuzAmma/
├── App/
│   ├── JuzAmmaApp.swift          # App entry point
│   └── ContentView.swift          # Root view with data loading
├── Models/
│   ├── Surah.swift                # Surah & Ayah data models
│   └── AppSettings.swift          # User preferences
├── Services/
│   └── QuranDataService.swift     # Data management layer
├── Features/
│   ├── SurahList/
│   │   └── SurahListView.swift    # Main list with search
│   ├── SurahDetail/
│   │   └── SurahDetailView.swift  # Detailed surah view
│   └── Settings/
│       └── SettingsView.swift     # App settings
└── Resources/
    └── juz_amma_data.json         # Quran data (offline)
```

### Key Design Decisions
1. **SwiftData over Core Data** - Modern, type-safe persistence
2. **Offline-First** - Embedded JSON data, no API dependencies for core features
3. **Native SwiftUI** - No UIKit, pure SwiftUI for iOS 17+
4. **Accessibility** - VoiceOver, Dynamic Type, RTL support
5. **Clean Architecture** - MVVM with service layer

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ (for SwiftData support)
- macOS Sonoma 14.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/febbyRG/juz-amma.git
   cd juz-amma
   ```

2. **Open in Xcode**
   ```bash
   open JuzAmma.xcodeproj
   ```

3. **Build and Run**
   - Select target device/simulator (iOS 17+)
   - Press `Cmd + R` or click ▶️ Run

### First Launch
On first launch, the app will:
1. Load 37 surahs from `juz_amma_data.json`
2. Initialize SwiftData storage
3. Create default settings
4. Display the surah list

---

## 📊 Data Source

### Quran Data
- **Source**: Quran.com API (free, open-source)
- **Content**: Arabic text, transliterations, translations
- **Format**: JSON embedded in app bundle
- **Future**: Will integrate Quran.com API for audio and additional translations

### Translations
- **English**: Sahih International (default)
- **Indonesian**: Kementerian Agama RI
- **Future**: More translations will be added

---

## 🤲 Islamic Context

### What is Juz Amma?
**Juz Amma** (الجزء عم) is the 30th and final section (Juz) of the Holy Quran. It contains 37 short surahs (chapters) from **Surah An-Naba (78)** to **Surah An-Nas (114)**.

### Why Juz Amma?
- Most commonly memorized section of the Quran
- Used daily in Salat (prayer)
- Starting point for Quran memorization
- Contains essential Islamic teachings

### Purpose of This App
This app is created as **Sadaqah Jariyah** (ongoing charity) to:
- Help Muslims worldwide memorize the Quran
- Make Islamic learning accessible and beautiful
- Demonstrate modern iOS development with SwiftUI
- Contribute to the Islamic tech ecosystem

---

## 🛠️ Development

### SwiftUI Patterns Used
```swift
// SwiftData Models with @Model macro
@Model
final class Surah {
    var number: Int
    var nameArabic: String
    // ... properties
}

// SwiftUI Views with @Query
@Query(sort: \Surah.number) 
private var surahs: [Surah]

// Navigation with NavigationStack
NavigationStack {
    // Typed navigation
    .navigationDestination(for: Surah.self) { surah in
        SurahDetailView(surah: surah)
    }
}

// Theme support with preferredColorScheme
.preferredColorScheme(settings.themeMode == .dark ? .dark : .light)
```

### Adding New Features
1. Create feature folder in `Features/`
2. Implement SwiftUI View
3. Add to navigation if needed
4. Update models/services as required
5. Write unit tests (coming soon)

### Code Style
- **SwiftLint** (coming soon) for consistency
- **Naming**: PascalCase for types, camelCase for variables
- **Comments**: Explain "why", not "what"
- **Documentation**: Use `/// ` for public APIs

---

## 🧪 Testing

> Unit tests and UI tests coming in Phase 2

---

## 📦 Distribution

### App Store
- **Status**: In development
- **Target**: Release Q1 2025
- **Price**: Free, no ads, no in-app purchases

### Open Source
- **License**: MIT (tentative)
- **Contributions**: Welcome! See CONTRIBUTING.md (coming soon)
- **Community**: GitHub Discussions for ideas

---

## 🤝 Contributing

This project is open for contributions! Whether you're:
- 🐛 Fixing bugs
- ✨ Adding features
- 📝 Improving documentation
- 🌍 Adding translations
- 🎨 Designing UI/UX

All contributions are welcome! More details in CONTRIBUTING.md (coming soon).

---

## 📜 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Febby Rachmat Gumilar** ([@febbyRG](https://github.com/febbyRG))
- 14+ years software development
- iOS developer since 2013
- Solo Developer at MagLoft
- Based in Bandung, Indonesia 🇮🇩

---

## 🙏 Acknowledgments

- **Allah SWT** - For guidance and knowledge
- **Quran.com** - For open-source Quran data
- **Muslim Developer Community** - For inspiration
- **Apple** - For amazing SwiftUI framework

---

## 📞 Contact

- **GitHub**: [@febbyRG](https://github.com/febbyRG)
- **Email**: febby@magloft.com
- **Issues**: [GitHub Issues](https://github.com/febbyRG/juz-amma/issues)

---

<div align="center">

**Made with ❤️ and ☕ in Bandung, Indonesia**

*Bismillah, let's make Quranic learning accessible for everyone!* 🚀🤲

⭐ **Star this repo if you find it useful!**

</div>

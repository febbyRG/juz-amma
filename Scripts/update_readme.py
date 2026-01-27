#!/usr/bin/env python3
"""Script to update README.md with clean format and Phase 3."""

readme_content = """# Juz Amma - iOS App

A Modern SwiftUI App for Memorizing Juz Amma

Made with love for Muslims worldwide

---

## Overview

Juz Amma is an open-source iOS app designed to help Muslims memorize and practice the 37 surahs of Juz Amma (Juz 30) - the last section of the Holy Quran. Built with modern SwiftUI and SwiftData, the app provides a clean, distraction-free interface for Quranic learning.

### Features

**Phase 1 - Core Features (Completed)**
- Complete Juz Amma Collection - All 37 surahs (78-114)
- Arabic Text - Beautiful, readable Arabic typography with RTL support
- Transliteration - Latin text for pronunciation help
- Dual Translations - English and Bahasa Indonesia with more available
- Smart Search - Search by surah name, number, or translation
- Bookmark System - Quick access to favorite surahs
- Memorization Tracker - Track progress and set goals
- Theme Support - Light, Dark, and Auto modes
- Offline-First - All content works without internet
- SwiftData Storage - Modern local persistence

**Phase 2 - Audio Recitation (Completed)**
- Audio playback with multiple Qaris (reciters)
- Play full surah or individual verses
- Verse-by-verse highlighting synchronized with audio
- Playback speed control (0.5x to 1.5x)
- Repeat mode for memorization practice
- Background audio playback
- Streaming from Quran.com CDN

**Phase 3 - Offline Audio and Enhanced Features (Planned)**
- Download audio files for offline playback
- Audio cache management
- Storage usage display and cleanup
- Download progress indicators
- Resume interrupted downloads
- Practice mode for memorization testing
- Progress statistics and streaks
- Daily reminders and notifications

**Future Plans**
- Cloud sync with authentication
- Duas collection
- Islamic articles and videos
- Prayer times and Qibla direction
- Widgets for quick access

---

## Screenshots

Screenshots coming soon after UI refinement

---

## Architecture

### Tech Stack
- SwiftUI - Modern declarative UI framework
- SwiftData - Native persistence layer (iOS 17+)
- AVFoundation - Audio playback
- Combine - Reactive data flow
- Swift Concurrency - Async/await for data loading

### Project Structure

```
JuzAmma/
├── App/
│   ├── JuzAmmaApp.swift          # App entry point
│   └── ContentView.swift          # Root view with data loading
├── Core/
│   └── Constants.swift            # App-wide constants
├── Models/
│   ├── Surah.swift                # Surah and Ayah data models
│   ├── Qari.swift                 # Audio reciter models
│   ├── Translation.swift          # Translation models
│   └── AppSettings.swift          # User preferences
├── Services/
│   ├── QuranDataService.swift     # Data management layer
│   ├── TranslationService.swift   # Translation API service
│   └── AudioPlayerService.swift   # Audio playback service
├── Features/
│   ├── SurahList/
│   │   └── SurahListView.swift    # Main list with search
│   ├── SurahDetail/
│   │   └── SurahDetailView.swift  # Detailed surah view
│   ├── Audio/
│   │   └── AudioPlayerView.swift  # Audio player controls
│   ├── Settings/
│   │   ├── SettingsView.swift     # App settings
│   │   └── QariSettingsView.swift # Reciter selection
│   └── Translations/
│       └── TranslationManagerView.swift
└── Resources/
    └── juz_amma_data.json         # Quran data (offline)
```

### Key Design Decisions
1. SwiftData over Core Data - Modern, type-safe persistence
2. Offline-First - Embedded JSON data, no API dependencies for core features
3. Native SwiftUI - Pure SwiftUI for iOS 17+
4. Accessibility - VoiceOver, Dynamic Type, RTL support
5. Clean Architecture - MVVM with service layer
6. Unified Audio Source - Same audio file for surah and verse playback

---

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ (for SwiftData support)
- macOS Sonoma 14.0+

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/febbyRG/juz-amma.git
   cd juz-amma
   ```

2. Open in Xcode
   ```bash
   open JuzAmma.xcodeproj
   ```

3. Build and Run
   - Select target device/simulator (iOS 17+)
   - Press Cmd + R to run

### First Launch
On first launch, the app will:
1. Load 37 surahs from embedded JSON data
2. Initialize SwiftData storage
3. Create default settings
4. Display the surah list

---

## Data Source

### Quran Data
- Source: Quran.com API (free, open-source)
- Content: Arabic text, transliterations, translations
- Format: JSON embedded in app bundle
- Audio: Streaming from Quran.com CDN

### Translations Available
- English: Sahih International (default)
- Indonesian: Kementerian Agama RI
- Additional translations downloadable from Quran.com API

### Audio Reciters
- Mishary Rashid Alafasy (default)
- Abdul Basit (Murattal and Mujawwad)
- Abdur-Rahman as-Sudais
- Abu Bakr al-Shatri
- Mahmoud Khalil Al-Husary
- And many more from Quran.com

---

## Islamic Context

### What is Juz Amma?
Juz Amma is the 30th and final section (Juz) of the Holy Quran. It contains 37 short surahs from Surah An-Naba (78) to Surah An-Nas (114).

### Why Juz Amma?
- Most commonly memorized section of the Quran
- Used daily in Salat (prayer)
- Starting point for Quran memorization
- Contains essential Islamic teachings

### Purpose of This App
This app is created as Sadaqah Jariyah (ongoing charity) to:
- Help Muslims worldwide memorize the Quran
- Make Islamic learning accessible and beautiful
- Demonstrate modern iOS development with SwiftUI
- Contribute to the Islamic tech ecosystem

---

## Development

### Adding New Features
1. Create feature folder in Features/
2. Implement SwiftUI View
3. Add to navigation if needed
4. Update models/services as required
5. Write unit tests

### Code Style
- Naming: PascalCase for types, camelCase for variables
- Comments: Explain why, not what
- Documentation: Use /// for public APIs

---

## Testing

Unit tests and UI tests coming soon

---

## Distribution

### App Store
- Status: In development
- Price: Free, no ads, no in-app purchases

### Open Source
- License: MIT
- Contributions: Welcome

---

## Contributing

This project is open for contributions. Whether fixing bugs, adding features, improving documentation, adding translations, or designing UI/UX - all contributions are welcome.

---

## License

This project is licensed under the MIT License - see LICENSE file for details.

---

## Author

Febby Rachmat Gumilar (@febbyRG)
- 14+ years software development
- iOS developer since 2013
- Based in Bandung, Indonesia

---

## Acknowledgments

- Allah SWT - For guidance and knowledge
- Quran.com - For open-source Quran data and audio
- Muslim Developer Community - For inspiration
- Apple - For SwiftUI framework

---

## Contact

- GitHub: @febbyRG
- Email: febby@magloft.com
- Issues: GitHub Issues

---

Made with love in Bandung, Indonesia

Bismillah, let us make Quranic learning accessible for everyone!
"""

if __name__ == "__main__":
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))
    readme_path = os.path.join(script_dir, "..", "README.md")
    
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(readme_content)
    
    print(f"README.md updated successfully at {readme_path}")

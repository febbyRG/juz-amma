//
//  SurahDetailView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import SwiftUI
import SwiftData

struct SurahDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State var surah: Surah
    
    @State private var showTransliteration = true
    @State private var showEnglish = true
    @State private var showIndonesian = true
    @State private var fontSize: CGFloat = 20
    
    private var service: QuranDataService {
        QuranDataService(modelContext: modelContext)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Surah Header
                SurahHeader(surah: surah)
                    .padding(.horizontal)
                
                // Bismillah (except for Surah 9)
                if surah.number != 9 {
                    BismillahView()
                        .padding(.horizontal)
                }
                
                // Ayah List
                if let ayahs = surah.ayahs, !ayahs.isEmpty {
                    VStack(spacing: 20) {
                        ForEach(ayahs.sorted(by: { $0.number < $1.number })) { ayah in
                            AyahView(
                                ayah: ayah,
                                showTransliteration: showTransliteration,
                                showEnglish: showEnglish,
                                showIndonesian: showIndonesian,
                                fontSize: fontSize
                            )
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // No ayahs loaded yet
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("Ayahs not available yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Full content will be added soon")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Bookmark
                    Button {
                        toggleBookmark()
                    } label: {
                        Label(
                            surah.isBookmarked ? "Remove Bookmark" : "Bookmark",
                            systemImage: surah.isBookmarked ? "bookmark.fill" : "bookmark"
                        )
                    }
                    
                    // Memorization
                    Button {
                        toggleMemorization()
                    } label: {
                        Label(
                            surah.isMemorized ? "Mark as Not Memorized" : "Mark as Memorized",
                            systemImage: surah.isMemorized ? "checkmark.circle.fill" : "checkmark.circle"
                        )
                    }
                    
                    // Set as Next to Memorize
                    Button {
                        setAsNextToMemorize()
                    } label: {
                        Label("Set as Next to Memorize", systemImage: "star.circle")
                    }
                    
                    Divider()
                    
                    // Display Options
                    Menu {
                        Toggle("Transliteration", isOn: $showTransliteration)
                        Toggle("English", isOn: $showEnglish)
                        Toggle("Indonesian", isOn: $showIndonesian)
                    } label: {
                        Label("Display Options", systemImage: "eye")
                    }
                    
                    // Font Size
                    Menu {
                        Button("Small") { fontSize = 16 }
                        Button("Medium") { fontSize = 20 }
                        Button("Large") { fontSize = 24 }
                        Button("Extra Large") { fontSize = 28 }
                    } label: {
                        Label("Font Size", systemImage: "textformat.size")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            updateLastAccessed()
        }
    }
    
    private func toggleBookmark() {
        do {
            try service.toggleBookmark(for: surah)
        } catch {
            print("Failed to toggle bookmark: \(error.localizedDescription)")
        }
    }
    
    private func toggleMemorization() {
        do {
            try service.toggleMemorization(for: surah)
        } catch {
            print("Failed to toggle memorization: \(error.localizedDescription)")
        }
    }
    
    private func setAsNextToMemorize() {
        do {
            try service.setNextToMemorize(surah)
        } catch {
            print("Failed to set next to memorize: \(error.localizedDescription)")
        }
    }
    
    private func updateLastAccessed() {
        surah.lastAccessedDate = Date()
        do {
            try modelContext.save()
        } catch {
            print("Failed to update last accessed date: \(error.localizedDescription)")
        }
    }
}

// MARK: - Surah Header
struct SurahHeader: View {
    let surah: Surah
    
    var body: some View {
        VStack(spacing: 12) {
            // Arabic Name (Large)
            Text(surah.nameArabic)
                .font(.custom("GeezaPro-Bold", size: 40))
                .environment(\.layoutDirection, .rightToLeft)
            
            // Transliteration & Translation
            Text(surah.nameTransliteration)
                .font(.title2.bold())
            
            Text(surah.nameTranslation)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Metadata
            HStack(spacing: 16) {
                Label("\(surah.ayahCount) ayahs", systemImage: "text.justify")
                Text("•")
                Label(surah.revelation, systemImage: "location")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            // Status Badges
            HStack(spacing: 12) {
                if surah.isMemorized {
                    Badge(text: "Memorized", color: .green, icon: "checkmark.circle.fill")
                }
                
                if surah.isBookmarked {
                    Badge(text: "Bookmarked", color: .blue, icon: "bookmark.fill")
                }
                
                if surah.isNextToMemorize {
                    Badge(text: "Next to Memorize", color: .yellow, icon: "star.fill")
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Bismillah View
struct BismillahView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                .font(.custom("GeezaPro", size: 24))
                .environment(\.layoutDirection, .rightToLeft)
            
            Text("Bismillahir Rahmanir Rahim")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Ayah View
struct AyahView: View {
    let ayah: Ayah
    let showTransliteration: Bool
    let showEnglish: Bool
    let showIndonesian: Bool
    let fontSize: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ayah Number Badge
            HStack {
                Text("\(ayah.number)")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            // Arabic Text (RTL, larger font)
            // Using Amiri Quran font for proper harakat rendering
            Text(ayah.textArabic)
                .font(.custom("Amiri Quran", size: fontSize + 8))
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .lineSpacing(14)
                .padding(.vertical, 8)
            
            // Transliteration
            if showTransliteration && !ayah.textTransliteration.isEmpty {
                Text(ayah.textTransliteration)
                    .font(.system(size: fontSize - 2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .italic()
            }
            
            // English Translation
            if showEnglish && !ayah.translationEnglish.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Text(ayah.translationEnglish)
                        .font(.system(size: fontSize - 2))
                        .foregroundStyle(.primary)
                    
                    Image(systemName: "quote.closing")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Indonesian Translation
            if showIndonesian && !ayah.translationIndonesian.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Text(ayah.translationIndonesian)
                        .font(.system(size: fontSize - 2))
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "quote.closing")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Badge Component
struct Badge: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        SurahDetailView(surah: Surah(
            number: 112,
            nameArabic: "الإخلاص",
            nameTransliteration: "Al-Ikhlas",
            nameTranslation: "The Sincerity",
            ayahCount: 4,
            revelation: "Makkah"
        ))
    }
    .modelContainer(for: [Surah.self, Ayah.self, AppSettings.self], inMemory: true)
}

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
    @Query private var appSettings: [AppSettings]
    @State var surah: Surah
    
    @State private var fontSize: CGFloat = 20
    @State private var showTranslationPicker = false
    @State private var showTranslationManager = false
    @State private var availableTranslations: [DownloadedTranslation] = []
    @State private var showAudioPlayer = false
    @State private var showQariPicker = false
    @State private var showAudioOptions = false
    @State private var errorMessage: String?
    @EnvironmentObject private var audioService: AudioPlayerService
    
    private var settings: AppSettings? {
        appSettings.first
    }
    
    /// Lazily-created ViewModel backed by the Environment's ModelContext
    private var viewModel: SurahDetailViewModel {
        SurahDetailViewModel(modelContext: modelContext)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    // Surah Header with Play Button
                    SurahHeader(surah: surah, audioService: audioService)
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
                                    fontSize: fontSize,
                                    settings: settings,
                                    audioService: audioService,
                                    surahNumber: surah.number
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
                    
                    // Bottom padding for audio player
                    if showAudioPlayer {
                        Spacer()
                            .frame(height: 80)
                    }
                }
                .padding(.vertical)
            }
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
                        toggleNextToMemorize()
                    } label: {
                        Label(
                            surah.isNextToMemorize ? "Remove from Next to Memorize" : "Set as Next to Memorize",
                            systemImage: surah.isNextToMemorize ? "star.circle.fill" : "star.circle"
                        )
                    }
                    
                    Divider()
                    
                    // Display Options
                    Menu {
                        Button {
                            showTranslationPicker = true
                        } label: {
                            Label("Select Translation", systemImage: "globe")
                        }
                        
                        Toggle("Show Both Translations", isOn: Binding(
                            get: { settings?.showBothTranslations ?? false },
                            set: { newValue in
                                viewModel.updateShowBothTranslations(newValue, settings: settings)
                            }
                        ))
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
            
            // Audio Play Button in toolbar
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if audioService.state.isPlaying {
                        audioService.pause()
                    } else if audioService.state == .paused {
                        audioService.resume()
                    } else {
                        showAudioPlayer = true
                        Task {
                            await audioService.playSurahFull(surah.number, surahName: surah.nameTransliteration)
                        }
                    }
                } label: {
                    Image(systemName: audioService.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.primaryGreen)
                }
            }
        }
        // Audio Player overlay
        .safeAreaInset(edge: .bottom) {
            if showAudioPlayer || audioService.state != .idle {
                AudioPlayerView(
                    audioService: audioService,
                    surahNumber: surah.number,
                    surahName: surah.nameTransliteration,
                    onShowQariPicker: {
                        showQariPicker = true
                    },
                    onShowOptionsSheet: {
                        showAudioOptions = true
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .sheet(isPresented: $showTranslationPicker) {
            TranslationPickerView(
                availableTranslations: availableTranslations,
                onManageTranslations: {
                    showTranslationPicker = false
                    showTranslationManager = true
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTranslationManager) {
            NavigationStack {
                TranslationManagerView()
            }
        }
        .sheet(isPresented: $showQariPicker) {
            QariPickerView(
                selectedQari: audioService.selectedQari,
                onSelect: { qari in
                    audioService.setQari(qari)
                    showQariPicker = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAudioOptions) {
            AudioOptionsSheet(
                audioService: audioService,
                onShowQariPicker: {
                    showQariPicker = true
                }
            )
        }
        .onChange(of: showTranslationManager) { _, isShowing in
            // Reload translations when coming back from TranslationManagerView
            if !isShowing {
                loadAvailableTranslations()
            }
        }
        .onAppear {
            updateLastAccessed()
            loadAvailableTranslations()
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func toggleBookmark() {
        var vm = viewModel
        vm.toggleBookmark(for: surah)
        errorMessage = vm.errorMessage
    }
    
    private func toggleMemorization() {
        var vm = viewModel
        vm.toggleMemorization(for: surah)
        errorMessage = vm.errorMessage
    }
    
    private func toggleNextToMemorize() {
        var vm = viewModel
        vm.toggleNextToMemorize(for: surah)
        errorMessage = vm.errorMessage
    }
    
    private func updateLastAccessed() {
        viewModel.updateLastAccessed(for: surah)
    }
    
    private func loadAvailableTranslations() {
        var vm = viewModel
        vm.loadAvailableTranslations()
        availableTranslations = vm.availableTranslations
        errorMessage = vm.errorMessage
    }
}

// MARK: - Surah Header
struct SurahHeader: View {
    let surah: Surah
    @ObservedObject var audioService: AudioPlayerService
    
    var body: some View {
        VStack(spacing: 12) {
            // Arabic Name (Large)
            Text(surah.nameArabic)
                .font(.custom(AppConstants.Fonts.arabicDisplayBold, size: 40))
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
            
            // Play Audio Button
            Button {
                if audioService.state.isPlaying {
                    audioService.pause()
                } else if audioService.state == .paused {
                    audioService.resume()
                } else {
                    Task {
                        await audioService.playSurahFull(surah.number, surahName: surah.nameTransliteration)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if audioService.state.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: audioService.state.isPlaying ? "pause.fill" : "play.fill")
                    }
                    Text(audioService.state.isPlaying ? "Pause" : "Play Surah")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppColors.primaryGreen)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
            
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
    let fontSize: CGFloat
    let settings: AppSettings?
    @ObservedObject var audioService: AudioPlayerService
    let surahNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ayah Number Badge with Audio Button
            HStack {
                Text("\(ayah.number)")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(Capsule())
                
                Spacer()
                
                // Verse Audio Button
                VerseAudioButton(
                    audioService: audioService,
                    surahNumber: surahNumber,
                    verseNumber: ayah.number
                )
            }
            
            // Arabic Text (RTL, larger font)
            // Using Amiri Quran font for proper harakat rendering
            Text(ayah.textArabic)
                .font(.custom(AppConstants.Fonts.quranArabic, size: fontSize + 8))
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .lineSpacing(14)
                .padding(.vertical, 8)
            
            // Latin Transliteration
            if !ayah.textTransliteration.isEmpty {
                Text(ayah.textTransliteration)
                    .font(.system(size: fontSize - 2, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
            }
            
            // Dynamic Translations
            if let settings = settings {
                // Primary Translation
                let primaryTranslation = ayah.getTranslation(languageCode: settings.primaryTranslationLanguage)
                if let primaryTranslation = primaryTranslation {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        Text(primaryTranslation)
                            .font(.system(size: fontSize - 2))
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "quote.closing")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // Secondary Translation (if enabled)
                if settings.showBothTranslations {
                    if let secondaryLang = settings.secondaryTranslationLanguage,
                       let secondaryTranslation = ayah.getTranslation(languageCode: secondaryLang) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            
                            Text(secondaryTranslation)
                                .font(.system(size: fontSize - 2))
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "quote.closing")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
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
    .environmentObject(AudioPlayerService())
    .modelContainer(for: [Surah.self, Ayah.self, AppSettings.self, Translation.self], inMemory: true)
}

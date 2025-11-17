//
//  SurahListView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import SwiftUI
import SwiftData

struct SurahListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Surah.number) private var surahs: [Surah]
    
    @State private var searchText = ""
    @State private var showBookmarksOnly = false
    @State private var showMemorizedOnly = false
    
    private var filteredSurahs: [Surah] {
        var filtered = surahs
        
        // Filter by bookmarks
        if showBookmarksOnly {
            filtered = filtered.filter { $0.isBookmarked }
        }
        
        // Filter by memorized
        if showMemorizedOnly {
            filtered = filtered.filter { $0.isMemorized }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { surah in
                surah.nameArabic.contains(searchText) ||
                surah.nameTransliteration.localizedCaseInsensitiveContains(searchText) ||
                surah.nameTranslation.localizedCaseInsensitiveContains(searchText) ||
                String(surah.number).contains(searchText)
            }
        }
        
        return filtered
    }
    
    private var nextToMemorize: Surah? {
        surahs.first(where: { $0.isNextToMemorize })
    }
    
    private var memorizedCount: Int {
        surahs.filter { $0.isMemorized }.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Card
                if !surahs.isEmpty {
                    ProgressCard(memorizedCount: memorizedCount, totalCount: surahs.count)
                        .padding()
                }
                
                // Next to Memorize Card
                if let next = nextToMemorize {
                    NextToMemorizeCard(surah: next)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "Bookmarks",
                            icon: "bookmark.fill",
                            isActive: showBookmarksOnly
                        ) {
                            showBookmarksOnly.toggle()
                            if showBookmarksOnly {
                                showMemorizedOnly = false
                            }
                        }
                        
                        FilterChip(
                            title: "Memorized",
                            icon: "checkmark.circle.fill",
                            isActive: showMemorizedOnly
                        ) {
                            showMemorizedOnly.toggle()
                            if showMemorizedOnly {
                                showBookmarksOnly = false
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // Surah List
                if filteredSurahs.isEmpty {
                    EmptyStateView(
                        icon: searchText.isEmpty ? "book.closed" : "magnifyingglass",
                        message: searchText.isEmpty ? "No surahs found" : "No results for '\(searchText)'"
                    )
                } else {
                    List {
                        ForEach(filteredSurahs) { surah in
                            NavigationLink(value: surah) {
                                SurahRow(surah: surah)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Juz Amma")
            .navigationDestination(for: Surah.self) { surah in
                SurahDetailView(surah: surah)
            }
            .searchable(text: $searchText, prompt: "Search surahs...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}

// MARK: - Surah Row
struct SurahRow: View {
    let surah: Surah
    
    var body: some View {
        HStack(spacing: 16) {
            // Surah Number Circle
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text("\(surah.number)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            
            // Surah Info
            VStack(alignment: .leading, spacing: 4) {
                Text(surah.nameTransliteration)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(surah.nameTranslation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("\(surah.ayahCount) ayahs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Arabic Name
            Text(surah.nameArabic)
                .font(.custom("GeezaPro", size: 20))
                .environment(\.layoutDirection, .rightToLeft)
            
            // Status Indicators
            VStack(spacing: 4) {
                if surah.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
                
                if surah.isMemorized {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let memorizedCount: Int
    let totalCount: Int
    
    private var progress: Double {
        totalCount > 0 ? Double(memorizedCount) / Double(totalCount) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memorization Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(memorizedCount) / \(totalCount)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            
            ProgressView(value: progress)
                .tint(Color.accentColor)
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Next to Memorize Card
struct NextToMemorizeCard: View {
    let surah: Surah
    
    var body: some View {
        NavigationLink(value: surah) {
            HStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next to Memorize")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(surah.nameTransliteration)
                        .font(.headline)
                }
                
                Spacer()
                
                Text(surah.nameArabic)
                    .font(.custom("GeezaPro", size: 18))
                    .environment(\.layoutDirection, .rightToLeft)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isActive ? Color.accentColor : Color.gray.opacity(0.2))
            .foregroundStyle(isActive ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SurahListView()
        .modelContainer(for: [Surah.self, Ayah.self, AppSettings.self, Translation.self], inMemory: true)
}

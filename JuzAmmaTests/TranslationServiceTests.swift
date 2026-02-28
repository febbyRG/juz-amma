//
//  TranslationServiceTests.swift
//  JuzAmmaTests
//
//  Created by Febby Rachmat on 01/03/26.
//

import Testing
import Foundation
import SwiftData
@testable import Juz_Amma

// MARK: - Text Cleaning Tests

@Suite(.serialized)
@MainActor
struct TranslationTextCleaningTests {

    private func makeService() throws -> TranslationService {
        let schema = Schema([Surah.self, Ayah.self, AppSettings.self, Translation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return TranslationService(modelContext: container.mainContext)
    }

    @Test func removesFootnoteSupTags() throws {
        let service = try makeService()
        let input = "Some text<sup foot_note=123>1</sup> more text"
        let result = service.cleanTranslationText(input)
        #expect(result == "Some text more text")
    }

    @Test func removesNestedSupTags() throws {
        let service = try makeService()
        let input = "Word<sup class=\"test\">2</sup> end"
        let result = service.cleanTranslationText(input)
        #expect(result == "Word end")
    }

    @Test func removesHtmlTagsKeepsContent() throws {
        let service = try makeService()
        let result = service.cleanTranslationText("<p>Hello <b>World</b></p>")
        #expect(result == "Hello World")
    }

    @Test func replacesHtmlEntities() throws {
        let service = try makeService()
        let result = service.cleanTranslationText("A &amp; B &lt;C&gt;")
        #expect(result == "A & B <C>")
    }

    @Test func replacesNbsp() throws {
        let service = try makeService()
        let result = service.cleanTranslationText("word&nbsp;word")
        #expect(result == "word word")
    }

    @Test func replacesQuoteEntities() throws {
        let service = try makeService()
        let result = service.cleanTranslationText("&quot;hello&quot; &apos;world&apos; &#39;test&#39;")
        #expect(result == "\"hello\" 'world' 'test'")
    }

    @Test func collapsesMultipleSpaces() throws {
        let service = try makeService()
        let result = service.cleanTranslationText("word   word    word")
        #expect(result == "word word word")
    }

    @Test func trimsWhitespace() throws {
        let service = try makeService()
        let result = service.cleanTranslationText("  hello world  ")
        #expect(result == "hello world")
    }

    @Test func handlesComplexHtml() throws {
        let service = try makeService()
        let input = "<p>Say, <sup foot_note=12345>1</sup>&quot;He is Allah, <b>[who is]</b> One&quot;</p>"
        let result = service.cleanTranslationText(input)
        #expect(result == "Say, \"He is Allah, [who is] One\"")
    }

    @Test func handlesEmptyString() throws {
        let service = try makeService()
        let result = service.cleanTranslationText("")
        #expect(result == "")
    }

    @Test func handlePlainTextUnchanged() throws {
        let service = try makeService()
        let input = "This is plain text with no HTML"
        let result = service.cleanTranslationText(input)
        #expect(result == input)
    }
}

// MARK: - TranslationService DI Tests

@Suite(.serialized)
@MainActor
struct TranslationServiceDITests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Surah.self, Ayah.self, AppSettings.self, Translation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func fetchAvailableTranslationsUsesMockNetwork() async throws {
        let container = try makeContainer()
        let mock = MockNetworkService()
        let service = TranslationService(modelContext: container.mainContext, networkService: mock)

        let url = URL(string: "\(AppConstants.API.baseURL)\(AppConstants.API.translationsEndpoint)")!

        // Build a minimal valid response
        let responseJSON: [String: Any] = [
            "translations": [
                [
                    "id": 20,
                    "name": "Saheeh International",
                    "author_name": "Saheeh International",
                    "language_name": "english"
                ]
            ]
        ]
        mock.mockResponses[url] = try JSONSerialization.data(withJSONObject: responseJSON)

        let translations = try await service.fetchAvailableTranslations()
        #expect(translations.count == 1)
        #expect(translations.first?.id == 20)
        #expect(mock.fetchCallCount == 1)
    }

    @Test func fetchThrowsWhenNetworkFails() async throws {
        let container = try makeContainer()
        let mock = MockNetworkService()
        mock.mockError = NetworkError.httpError(statusCode: 500)
        let service = TranslationService(modelContext: container.mainContext, networkService: mock)

        do {
            _ = try await service.fetchAvailableTranslations()
            Issue.record("Expected error")
        } catch {
            #expect(error is NetworkError)
        }
    }

    @Test func deleteTranslation() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let service = TranslationService(modelContext: context)

        // Insert a translation
        let translation = Translation(id: 99, languageCode: "test", name: "Test", text: "text")
        context.insert(translation)
        try context.save()

        // Verify it exists
        #expect(try service.isTranslationDownloaded(translationId: 99) == true)

        // Delete it
        try service.deleteTranslation(translationId: 99)
        #expect(try service.isTranslationDownloaded(translationId: 99) == false)
    }

    @Test func getDownloadedTranslationIds() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let service = TranslationService(modelContext: context)

        // Insert translations with different IDs
        context.insert(Translation(id: 20, languageCode: "en", name: "English", text: "a"))
        context.insert(Translation(id: 20, languageCode: "en", name: "English", text: "b"))
        context.insert(Translation(id: 33, languageCode: "id", name: "Indonesian", text: "c"))
        try context.save()

        let ids = try service.getDownloadedTranslationIds()
        #expect(ids.count == 2)
        #expect(ids.contains(20))
        #expect(ids.contains(33))
    }

    @Test func translationStatsReturnsCorrectCounts() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let service = TranslationService(modelContext: context)

        context.insert(Translation(id: 20, languageCode: "en", name: "English", text: "hello"))
        context.insert(Translation(id: 33, languageCode: "id", name: "Indonesian", text: "halo"))
        try context.save()

        let stats = try service.getTranslationStats()
        #expect(stats.totalTranslations == 2)
        #expect(stats.uniqueLanguages == 2)
        #expect(stats.estimatedSize > 0)
        #expect(!stats.formattedSize.isEmpty)
    }
}

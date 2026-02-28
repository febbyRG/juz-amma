//
//  NetworkServiceTests.swift
//  JuzAmmaTests
//
//  Created by Febby Rachmat on 01/03/26.
//

import Testing
import Foundation
@testable import Juz_Amma

// MARK: - NetworkError Tests

struct NetworkErrorDescriptionTests {

    @Test func invalidURL() {
        let error = NetworkError.invalidURL
        #expect(error.errorDescription == "Invalid URL")
    }

    @Test func invalidResponse() {
        let error = NetworkError.invalidResponse
        #expect(error.errorDescription == "Invalid server response")
    }

    @Test func httpError401() {
        let error = NetworkError.httpError(statusCode: 401)
        #expect(error.errorDescription?.contains("Authentication") == true)
    }

    @Test func httpError403() {
        let error = NetworkError.httpError(statusCode: 403)
        #expect(error.errorDescription?.contains("forbidden") == true)
    }

    @Test func httpError404() {
        let error = NetworkError.httpError(statusCode: 404)
        #expect(error.errorDescription?.contains("not found") == true)
    }

    @Test func httpError429() {
        let error = NetworkError.httpError(statusCode: 429)
        #expect(error.errorDescription?.contains("Too many") == true)
    }

    @Test func httpError500() {
        let error = NetworkError.httpError(statusCode: 500)
        #expect(error.errorDescription?.contains("Server error") == true)
    }

    @Test func httpErrorGeneric() {
        let error = NetworkError.httpError(statusCode: 418)
        #expect(error.errorDescription?.contains("418") == true)
    }

    @Test func decodingError() {
        let underlying = NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "bad json"])
        let error = NetworkError.decodingError(underlying)
        #expect(error.errorDescription?.contains("parsing") == true)
    }

    @Test func requestFailed() {
        let underlying = NSError(domain: "test", code: -1009, userInfo: [NSLocalizedDescriptionKey: "no internet"])
        let error = NetworkError.requestFailed(underlying: underlying)
        #expect(error.errorDescription?.contains("failed") == true)
    }
}

// MARK: - NetworkError Equatable Tests

struct NetworkErrorEqualityTests {

    @Test func sameErrorsAreEqual() {
        #expect(NetworkError.invalidURL == NetworkError.invalidURL)
        #expect(NetworkError.invalidResponse == NetworkError.invalidResponse)
        #expect(NetworkError.httpError(statusCode: 404) == NetworkError.httpError(statusCode: 404))
        #expect(NetworkError.decodingError(NSError(domain: "", code: 0)) == NetworkError.decodingError(NSError(domain: "", code: 1)))
        #expect(NetworkError.requestFailed(underlying: NSError(domain: "", code: 0)) == NetworkError.requestFailed(underlying: NSError(domain: "", code: 1)))
    }

    @Test func differentErrorsAreNotEqual() {
        #expect(NetworkError.invalidURL != NetworkError.invalidResponse)
        #expect(NetworkError.httpError(statusCode: 404) != NetworkError.httpError(statusCode: 500))
    }
}

// MARK: - CachePolicy Tests

struct CachePolicyTests {

    @Test func networkOnlyCase() {
        let policy = CachePolicy.networkOnly
        if case .networkOnly = policy {
            // pass
        } else {
            Issue.record("Expected .networkOnly")
        }
    }

    @Test func cacheFirstCase() {
        let policy = CachePolicy.cacheFirst(maxAge: 300)
        if case .cacheFirst(let maxAge) = policy {
            #expect(maxAge == 300)
        } else {
            Issue.record("Expected .cacheFirst")
        }
    }
}

// MARK: - MockNetworkService Tests

struct MockNetworkServiceTests {

    @Test func returnsConfiguredResponse() async throws {
        let mock = MockNetworkService()
        let url = URL(string: "https://api.example.com/data")!

        struct TestResponse: Codable {
            let message: String
        }

        let jsonData = try JSONEncoder().encode(TestResponse(message: "hello"))
        mock.mockResponses[url] = jsonData

        let result: TestResponse = try await mock.fetch(TestResponse.self, from: url)
        #expect(result.message == "hello")
        #expect(mock.fetchCallCount == 1)
    }

    @Test func throwsConfiguredError() async {
        let mock = MockNetworkService()
        let url = URL(string: "https://api.example.com/fail")!
        mock.mockError = NetworkError.httpError(statusCode: 500)

        do {
            let _: [String: String] = try await mock.fetch([String: String].self, from: url)
            Issue.record("Expected error to be thrown")
        } catch let error as NetworkError {
            #expect(error == .httpError(statusCode: 500))
        } catch {
            Issue.record("Expected NetworkError, got \(type(of: error))")
        }
    }

    @Test func throwsInvalidResponseWhenNoMockData() async {
        let mock = MockNetworkService()
        let url = URL(string: "https://api.example.com/missing")!

        do {
            let _: [String: String] = try await mock.fetch([String: String].self, from: url)
            Issue.record("Expected error")
        } catch let error as NetworkError {
            #expect(error == .invalidResponse)
        } catch {
            Issue.record("Unexpected error type")
        }
    }

    @Test func fetchCallCountIncrements() async throws {
        let mock = MockNetworkService()
        let url = URL(string: "https://api.example.com/data")!
        mock.mockResponses[url] = try JSONEncoder().encode(["key": "value"])

        _ = try await mock.fetch([String: String].self, from: url)
        _ = try await mock.fetch([String: String].self, from: url)
        #expect(mock.fetchCallCount == 2)
    }

    @Test func defaultCachePolicyIsNetworkOnly() async throws {
        let mock = MockNetworkService()
        let url = URL(string: "https://api.example.com/data")!
        mock.mockResponses[url] = try JSONEncoder().encode(["key": "value"])

        // Calling fetch without cachePolicy uses the default .networkOnly (from protocol extension)
        let result: [String: String] = try await mock.fetch([String: String].self, from: url)
        #expect(result["key"] == "value")
    }

    @Test func resetClearsAllState() async {
        let mock = MockNetworkService()
        mock.mockResponses[URL(string: "https://x.com")!] = Data()
        mock.mockError = NetworkError.invalidURL

        mock.reset()

        #expect(mock.mockResponses.isEmpty)
        #expect(mock.mockError == nil)
        #expect(mock.fetchCallCount == 0)
    }
}

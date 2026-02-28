//
//  MockNetworkService.swift
//  JuzAmmaTests
//
//  Created by Febby Rachmat on 01/03/26.
//

import Foundation
@testable import Juz_Amma

/// Mock implementation of `NetworkServiceProtocol` for unit testing.
/// Configure `mockResponses` and `mockError` before each test.
final class MockNetworkService: NetworkServiceProtocol, @unchecked Sendable {

    // MARK: - Configuration

    /// Map of URL → raw JSON data to return from `fetch` / `fetchData`.
    var mockResponses: [URL: Data] = [:]

    /// When set, all calls throw this error instead of returning data.
    var mockError: Error?

    /// Number of times any fetch method has been called (useful for verifying caching).
    private(set) var fetchCallCount = 0

    // MARK: - NetworkServiceProtocol

    func fetch<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        cachePolicy: CachePolicy
    ) async throws -> T {
        fetchCallCount += 1
        if let error = mockError { throw error }
        guard let data = mockResponses[url] else {
            throw NetworkError.invalidResponse
        }
        return try JSONDecoder().decode(type, from: data)
    }

    func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        fetchCallCount += 1
        if let error = mockError { throw error }
        guard let data = mockResponses[url] else {
            throw NetworkError.invalidResponse
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    func clearCache() async {
        mockResponses.removeAll()
    }

    // MARK: - Helpers

    /// Reset all state between tests.
    func reset() {
        mockResponses.removeAll()
        mockError = nil
        fetchCallCount = 0
    }
}

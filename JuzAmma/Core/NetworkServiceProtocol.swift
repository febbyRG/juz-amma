//
//  NetworkServiceProtocol.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 01/03/26.
//

import Foundation

// MARK: - Cache Policy

/// Defines caching behavior for network requests.
enum CachePolicy: Sendable {
    /// Always fetch from network, never cache.
    case networkOnly
    /// Return cached response if available and within maxAge (seconds), otherwise fetch.
    case cacheFirst(maxAge: TimeInterval)
}

// MARK: - Network Service Protocol

/// Abstraction for network operations, enabling dependency injection and testability.
protocol NetworkServiceProtocol: Sendable {
    /// Fetch and decode a JSON response from the given URL.
    func fetch<T: Decodable>(_ type: T.Type, from url: URL, cachePolicy: CachePolicy) async throws -> T

    /// Fetch raw data from a URL.
    func fetchData(from url: URL) async throws -> (Data, URLResponse)

    /// Clear the in-memory response cache.
    func clearCache() async
}

// MARK: - Default Parameters

extension NetworkServiceProtocol {
    /// Convenience overload with default `.networkOnly` cache policy.
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        try await fetch(type, from: url, cachePolicy: .networkOnly)
    }
}

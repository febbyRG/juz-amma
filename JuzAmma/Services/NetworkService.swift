//
//  NetworkService.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 23/02/26.
//

import Foundation
import os

// MARK: - Network Service

/// Centralized networking layer with caching, error handling, and structured logging.
/// Uses actor isolation for thread-safe cache access.
actor NetworkService {
    
    // MARK: - Singleton
    
    static let shared = NetworkService()
    
    // MARK: - Properties
    
    private let session: URLSession
    private var responseCache: [URL: CachedResponse] = [:]
    
    // MARK: - Cached Response
    
    private struct CachedResponse {
        let data: Data
        let timestamp: Date
    }
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.Network.requestTimeout
        config.timeoutIntervalForResource = AppConstants.Network.resourceTimeout
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Fetch and decode a JSON response from the given URL.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode the response into.
    ///   - url: The request URL.
    ///   - cachePolicy: Whether to cache and/or return cached responses.
    /// - Returns: The decoded response.
    func fetch<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        cachePolicy: CachePolicy = .networkOnly
    ) async throws -> T {
        // Check in-memory cache
        if case .cacheFirst(let maxAge) = cachePolicy,
           let cached = responseCache[url],
           Date().timeIntervalSince(cached.timestamp) < maxAge {
            AppLogger.network.debug("Cache hit: \(url.lastPathComponent)")
            return try decodeJSON(type, from: cached.data, url: url)
        }
        
        let data = try await performRequest(url: url)
        
        // Store in cache when policy allows
        switch cachePolicy {
        case .cacheFirst:
            responseCache[url] = CachedResponse(data: data, timestamp: Date())
        case .networkOnly:
            break
        }
        
        return try decodeJSON(type, from: data, url: url)
    }
    
    /// Fetch raw data from a URL (for audio streaming, file downloads, etc.).
    func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        AppLogger.network.info("Fetching data: \(url.lastPathComponent)")
        
        do {
            let (data, response) = try await session.data(from: url)
            try validateHTTPResponse(response, url: url)
            return (data, response)
        } catch let error as NetworkError {
            throw error
        } catch {
            AppLogger.network.error("Request failed: \(error.localizedDescription)")
            throw NetworkError.requestFailed(underlying: error)
        }
    }
    
    /// Fetch raw bytes with progress support (for large downloads).
    func fetchBytes(from url: URL) async throws -> (URLSession.AsyncBytes, URLResponse) {
        AppLogger.network.info("Streaming bytes: \(url.lastPathComponent)")
        
        let (asyncBytes, response) = try await session.bytes(from: url)
        try validateHTTPResponse(response, url: url)
        return (asyncBytes, response)
    }
    
    /// Clear the in-memory response cache.
    func clearCache() {
        responseCache.removeAll()
        AppLogger.network.info("Response cache cleared")
    }
    
    // MARK: - Private Helpers
    
    private func performRequest(url: URL) async throws -> Data {
        AppLogger.network.info("Request: \(url.absoluteString)")
        
        do {
            let (data, response) = try await session.data(from: url)
            try validateHTTPResponse(response, url: url)
            AppLogger.network.debug("Response: \(data.count) bytes from \(url.lastPathComponent)")
            return data
        } catch let error as NetworkError {
            throw error
        } catch {
            AppLogger.network.error("Request failed: \(error.localizedDescription)")
            throw NetworkError.requestFailed(underlying: error)
        }
    }
    
    private func validateHTTPResponse(_ response: URLResponse, url: URL) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            AppLogger.network.error("HTTP \(httpResponse.statusCode): \(url.lastPathComponent)")
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    private func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data, url: URL) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            AppLogger.network.error("Decode failed for \(url.lastPathComponent): \(error.localizedDescription)")
            throw NetworkError.decodingError(error)
        }
    }
}

// MARK: - Cache Policy

extension NetworkService {
    /// Defines caching behavior for network requests.
    enum CachePolicy: Sendable {
        /// Always fetch from network, never cache.
        case networkOnly
        /// Return cached response if available and within maxAge (seconds), otherwise fetch.
        case cacheFirst(maxAge: TimeInterval)
    }
}

// MARK: - Network Errors

enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case requestFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return Self.descriptionForHTTPStatus(code)
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        }
    }
    
    private static func descriptionForHTTPStatus(_ code: Int) -> String {
        switch code {
        case 401:
            return "Authentication required"
        case 403:
            return "Access forbidden"
        case 404:
            return "Resource not found"
        case 429:
            return "Too many requests. Please try again later."
        case 500...599:
            return "Server error (\(code)). Please try again later."
        default:
            return "HTTP error \(code)"
        }
    }
    
    // Sendable conformance for associated Error values
    // These are created at throw-site and consumed at catch-site, crossing no boundaries
}

// Make NetworkError Equatable for testing
extension NetworkError: Equatable {
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case (.invalidResponse, .invalidResponse): return true
        case (.httpError(let l), .httpError(let r)): return l == r
        case (.decodingError, .decodingError): return true
        case (.requestFailed, .requestFailed): return true
        default: return false
        }
    }
}

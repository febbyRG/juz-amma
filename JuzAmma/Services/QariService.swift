//
//  QariService.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 10/02/26.
//

import Foundation

/// Lightweight service for fetching Qari (reciter) data from API
/// Avoids creating heavy AudioPlayerService instances just for API calls
enum QariService {
    
    /// Fetch available reciters from Quran.com API (cached for 5 min)
    static func fetchAvailableReciters() async throws -> [Qari] {
        let urlString = "\(AppConstants.API.baseURL)\(AppConstants.API.recitationsEndpoint)"
        
        guard let url = URL(string: urlString) else {
            throw AudioError.invalidURL
        }
        
        let response = try await NetworkService.shared.fetch(
            RecitationsResponse.self,
            from: url,
            cachePolicy: .cacheFirst(maxAge: AppConstants.Network.recitersCacheDuration)
        )
        return response.recitations.map { $0.toQari() }
    }
}

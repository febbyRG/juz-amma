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
    
    /// Fetch available reciters from Quran.com API
    static func fetchAvailableReciters() async throws -> [Qari] {
        let urlString = "\(AppConstants.API.baseURL)\(AppConstants.API.recitationsEndpoint)"
        
        guard let url = URL(string: urlString) else {
            throw AudioError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RecitationsResponse.self, from: data)
        return response.recitations.map { $0.toQari() }
    }
}

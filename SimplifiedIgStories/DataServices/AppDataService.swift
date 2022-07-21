//
//  AppDataService.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import Foundation

// MARK: - DataServiceError
enum DataServiceError: Error {
    case jsonFileNotFound
    case other(Error)
    
    var errMsg: String {
        switch self {
        case .jsonFileNotFound:
            return "JSON file not found."
        case .other(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - DataService
protocol DataService {
    func fetchStories() async throws -> [Story]
}

// MARK: - AppDataService
final class AppDataService: DataService {
    private let filename = "storiesData.json"
    
    func fetchStories() async throws -> [Story] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            throw DataServiceError.jsonFileNotFound
        }
        
        // Simulate an async API call.
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let stories = try JSONDecoder().decode([Story].self, from: data)
            
            return stories
        } catch {
            throw DataServiceError.other(error)
        }
    }
}

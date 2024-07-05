//
//  LocalStoriesLoader.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

final class LocalStoriesLoader: StoriesLoader {
    private let client: DataClient
    
    init(client: DataClient) {
        self.client = client
    }
    
    func load() async throws -> [Story] {
        guard let data = try? await client.fetch() else {
            throw StoriesLoaderError.notFound
        }
        
        guard let stories = try? StoriesMapper.map(data) else {
            throw StoriesLoaderError.invalidData
        }
        
        return stories
    }
}

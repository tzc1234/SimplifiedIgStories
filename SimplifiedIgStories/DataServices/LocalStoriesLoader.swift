//
//  LocalStoriesLoader.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

protocol StoriesLoader {
    func load() async throws -> [LocalStory]
}

enum StoriesLoaderError: Error {
    case notFound
    case invalidData
}

final class LocalStoriesLoader: StoriesLoader {
    private let client: DataClient
    
    init(client: DataClient) {
        self.client = client
    }
    
    func load() async throws -> [LocalStory] {
        guard let data = try? await client.fetch() else {
            throw StoriesLoaderError.notFound
        }
        
        guard let stories = try? LocalStoriesMapper.map(data) else {
            throw StoriesLoaderError.invalidData
        }
        
        return stories
    }
}

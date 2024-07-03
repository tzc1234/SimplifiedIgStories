//
//  StoriesLoader.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 03/07/2024.
//

import Foundation

protocol StoriesLoader {
    func load() async throws -> [LocalStory]
}

enum StoriesLoaderError: Error {
    case notFound
    case invalidData
}

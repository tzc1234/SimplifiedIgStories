//
//  StoryComponentCache.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 20/03/2024.
//

import Foundation

final class StoryComponentCache<T> {
    typealias StoryId = Int
    
    private var cache = [StoryId: T]()
    
    func save(_ component: T, for storyId: StoryId) {
        cache[storyId] = component
    }
    
    func getComponent(for storyId: StoryId) -> T? {
        cache[storyId]
    }
    
    func removeComponent(for storyId: StoryId) {
        cache[storyId] = nil
    }
}

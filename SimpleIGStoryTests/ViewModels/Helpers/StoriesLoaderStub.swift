//
//  StoriesLoaderStub.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 30/06/2024.
//

import Foundation
@testable import Simple_IG_Story

final class StoriesLoaderStub: StoriesLoader {
    private let stories: [Story]
    
    init(stories: [Story]) {
        self.stories = stories
    }
    
    func load() async throws -> [Story] {
        stories
    }
}

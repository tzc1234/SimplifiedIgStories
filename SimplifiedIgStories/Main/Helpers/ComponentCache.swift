//
//  ComponentCache.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 20/03/2024.
//

import Foundation

final class ComponentCache<I: Hashable, T> {
    private var cache = [I: T]()
    
    func save(_ component: T, for index: I) {
        cache[index] = component
    }
    
    func getComponent(for index: I) -> T? {
        cache[index]
    }
    
    func removeComponent(for index: I) {
        cache[index] = nil
    }
}

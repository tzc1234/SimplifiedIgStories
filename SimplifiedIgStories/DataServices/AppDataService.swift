//
//  AppDataService.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import Foundation

protocol DataService {
    func loadStories() -> [Story]
}

final class AppDataService: DataService {
    // Mock the data as coming from an api call.
    func loadStories() -> [Story] {
        let stories: [Story] = load("storiesData.json")
        return stories
    }
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
        
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

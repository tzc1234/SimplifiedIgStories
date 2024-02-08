//
//  LocalStoriesLoader.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

final class LocalStoriesLoader {
    private let client: DataClient
    
    init(client: DataClient) {
        self.client = client
    }
    
    enum Error: Swift.Error {
        case notFound
        case invalidData
    }
    
    private struct DecodableStory: Decodable {
        let id: Int
        let lastUpdate: TimeInterval?
        let user: User
        let portions: [Portion]
        
        var local: LocalStory {
            .init(
                id: id,
                lastUpdate: lastUpdate.map(Date.init(timeIntervalSince1970:)),
                user: user.local,
                portions: portions.map(\.local)
            )
        }
        
        struct User: Decodable {
            let id: Int
            let name: String
            let avatar: String
            let isCurrentUser: Bool
            
            var local: LocalUser {
                .init(id: id, name: name, avatar: avatar, isCurrentUser: isCurrentUser)
            }
        }
        
        struct Portion: Decodable {
            let id: Int
            let resource: String
            let duration: Double?
            let type: String
            
            var local: LocalPortion {
                .init(
                    id: id,
                    resource: resource,
                    duration: duration ?? .defaultStoryDuration,
                    type: .init(rawValue: type) ?? .image
                )
            }
        }
    }

    func load() async throws -> [LocalStory] {
        guard let data = try? await client.fetch() else {
            throw Error.notFound
        }
        
        guard let stories = try? JSONDecoder().decode([DecodableStory].self, from: data) else {
            throw Error.invalidData
        }
        
        return stories.map(\.local)
    }
}

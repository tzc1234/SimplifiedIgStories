//
//  LocalStoriesMapper.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

enum LocalStoriesMapper {
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
                .init(
                    id: id,
                    name: name,
                    avatarURL: Bundle.main.url(forResource: avatar, withExtension: "jpg"),
                    isCurrentUser: isCurrentUser
                )
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
    
    static func map(_ data: Data) throws -> [LocalStory] {
        try JSONDecoder().decode([DecodableStory].self, from: data).map(\.local)
    }
}

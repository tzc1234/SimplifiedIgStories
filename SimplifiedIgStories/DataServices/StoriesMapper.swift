//
//  StoriesMapper.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

enum StoriesMapper {
    private struct DecodableStory: Decodable {
        let id: Int
        let lastUpdate: TimeInterval?
        let user: DecodableUser
        let portions: [DecodablePortion]
        
        var model: Story {
            Story(
                id: id,
                lastUpdate: lastUpdate.map(Date.init(timeIntervalSince1970:)),
                user: user.model,
                portions: portions.map(\.model)
            )
        }
        
        struct DecodableUser: Decodable {
            let id: Int
            let name: String
            let avatar: String
            let isCurrentUser: Bool
            
            var model: User {
                User(
                    id: id,
                    name: name,
                    avatarURL: Bundle.main.url(forResource: avatar, withExtension: "jpg"),
                    isCurrentUser: isCurrentUser
                )
            }
        }
        
        struct DecodablePortion: Decodable {
            let id: Int
            let resource: String
            let duration: Double?
            let type: String
            
            var model: Portion {
                Portion(
                    id: id,
                    resourceURL: Bundle.main.url(forResource: resource, withExtension: type == "video" ? "mp4" : "jpg"),
                    duration: duration ?? .defaultStoryDuration,
                    type: .init(rawValue: type) ?? .image
                )
            }
        }
    }
    
    static func map(_ data: Data) throws -> [Story] {
        try JSONDecoder().decode([DecodableStory].self, from: data).map(\.model)
    }
}

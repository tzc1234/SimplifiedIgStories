//
//  AppDataService.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import Foundation
import Combine

enum DataServiceError: Error {
    case jsonFileNotFound
    case other(Error)
    
    var errString: String {
        switch self {
        case .jsonFileNotFound:
            return "JSON file not found."
        case .other(let error):
            return error.localizedDescription
        }
    }
}

protocol DataServiceable {
    func fetchStories() -> AnyPublisher<[Story], DataServiceError>
}

final class AppDataService: DataServiceable {
    private let filename = "storiesData.json"
    
    func fetchStories() -> AnyPublisher<[Story], DataServiceError> {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            return Fail<[Story], DataServiceError>(error: .jsonFileNotFound)
                .eraseToAnyPublisher()
        }
        
        let publisher = URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Story].self, decoder: JSONDecoder())
            .catch { error in
                return Fail<[Story], DataServiceError>(error: .other(error))
            }
            .eraseToAnyPublisher()
        
        return publisher
    }
}

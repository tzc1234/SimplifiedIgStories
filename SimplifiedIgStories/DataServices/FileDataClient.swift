//
//  FileDataClient.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

final class FileDataClient: DataClient {
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    enum Error: Swift.Error {
        case empty
    }
    
    func fetch() async throws -> Data {
        let data = try Data(contentsOf: url)
        guard !data.isEmpty else {
            throw Error.empty
        }
        
        return data
    }
}

//
//  DataClient.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

protocol DataClient {
    func fetch() async throws -> Data
}

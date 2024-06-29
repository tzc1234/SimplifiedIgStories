//
//  DataClientStub.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 29/06/2024.
//

import Foundation
@testable import Simple_IG_Story

final class DataClientStub: DataClient {
    typealias Stub = Result<Data, Error>
    
    private var stub: Stub
    
    init(stub: Stub) {
        self.stub = stub
    }
    
    func fetch() async throws -> Data {
        try stub.get()
    }
}

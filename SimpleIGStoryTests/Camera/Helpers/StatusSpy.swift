//
//  StatusSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 19/02/2024.
//

import Combine

final class StatusSpy<Status> {
    private(set) var loggedStatuses = [Status]()
    private var cancellable: AnyCancellable?
    
    init(publisher: AnyPublisher<Status, Never>) {
        cancellable = publisher
            .sink { [weak self] status in
                self?.loggedStatuses.append(status)
            }
    }
}

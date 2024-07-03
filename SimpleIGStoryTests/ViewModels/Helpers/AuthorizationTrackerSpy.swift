//
//  AuthorizationTrackerSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 03/07/2024.
//

import Foundation
import Combine
@testable import Simple_IG_Story

final class AuthorizationTrackerSpy: DeviceAuthorizationTracker {
    private let authorizationPublisher = PassthroughSubject<Bool, Never>()
    private(set) var startTrackingCallCount = 0
    
    func getPublisher() -> AnyPublisher<Bool, Never> {
        authorizationPublisher.eraseToAnyPublisher()
    }
    
    func startTracking() {
        startTrackingCallCount += 1
    }
    
    func publish(permissionGranted: Bool) {
        authorizationPublisher.send(permissionGranted)
    }
}

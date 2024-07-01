//
//  DummyMediaSaver.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 30/06/2024.
//

import Foundation
@testable import Simple_IG_Story

final class DummyMediaSaver: MediaSaver {
    func saveImageData(_ data: Data) async throws {}
    func saveVideo(by url: URL) async throws {}
}

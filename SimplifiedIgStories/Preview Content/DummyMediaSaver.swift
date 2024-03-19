//
//  DummyMediaSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/03/2024.
//

import Foundation

final class DummyMediaSaver: MediaSaver {
    func saveImageData(_ data: Data) async throws {}
    func saveVideo(by url: URL) async throws {}
}

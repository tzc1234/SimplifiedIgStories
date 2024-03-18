//
//  DummyFileManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/03/2024.
//

import UIKit

final class DummyFileManager: FileManageable {
    func saveImage(_ image: UIImage, fileName: String) throws -> URL {
        URL(string: "file://any-image.jpg")!
    }
    
    func getImage(for url: URL) -> UIImage? {
        nil
    }
    
    func delete(for url: URL) throws {}
}

//
//  DummyFileManager.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 30/06/2024.
//

import UIKit
@testable import Simple_IG_Story

final class DummyFileManager: FileManageable {
    func saveImage(_ image: UIImage, fileName: String) throws -> URL {
        URL(string: "file://any-image.jpg")!
    }
    
    func getImage(for url: URL) -> UIImage? { nil }
    
    func delete(for url: URL) throws {}
}

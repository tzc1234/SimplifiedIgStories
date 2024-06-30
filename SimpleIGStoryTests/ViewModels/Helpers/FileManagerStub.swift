//
//  FileManagerStub.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 30/06/2024.
//

import UIKit
@testable import Simple_IG_Story

final class FileManagerStub: FileManageable {
    private let savedImageURL: () throws -> URL
    
    init(savedImageURL: @escaping () throws -> URL) {
        self.savedImageURL = savedImageURL
    }
    
    func saveImage(_ image: UIImage, fileName: String) throws -> URL {
        try savedImageURL()
    }
    
    func getImage(for url: URL) -> UIImage? { nil }
    
    func delete(for url: URL) throws {}
}

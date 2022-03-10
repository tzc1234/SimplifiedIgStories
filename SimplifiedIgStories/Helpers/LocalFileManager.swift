//
//  LocalFileManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 10/03/2022.
//

import Foundation
import UIKit

class LocalFileManager {
    static let instance = LocalFileManager()
    
    func saveImageToTemp(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("Error when getting image data.")
            return nil
        }
        
        let imageName = "img_\(UUID().uuidString)"
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("\(imageName).jpg")
        
        do {
            try data.write(to: url)
            print("Saving image: \(imageName) successful.")
            return url
        } catch let error {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getImageBy(url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

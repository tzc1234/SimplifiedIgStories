//
//  ImageSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import UIKit

class ImageSaver: NSObject {
    var saveCompletedAction: (() -> Void)?
    
    init(saveCompletedAction: (() -> Void)? = nil) {
        self.saveCompletedAction = saveCompletedAction
    }
    
    func saveImageToAlbum(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(performSaveImage), nil)
    }
    
    @objc private func performSaveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Save image error: \(error.localizedDescription)")
        } else {
            saveCompletedAction?()
        }
    }
}

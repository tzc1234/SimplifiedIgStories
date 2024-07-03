//
//  AppComponentsFactory.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 20/03/2024.
//

import Foundation

final class AppComponentsFactory {
    let fileManager = LocalFileManager()
    
    private let mediaStore = PHPPhotoMediaStore()
    private(set) lazy var mediaSaver = LocalMediaSaver(store: mediaStore)
    
    // storiesDataURL should not be nil, since storiesData.json is already embedded in Resource directory.
    private let storiesDataURL = Bundle.main.url(forResource: "storiesData.json", withExtension: nil)!
    private lazy var dataClient = FileDataClient(url: storiesDataURL)
    private lazy var storiesLoader = LocalStoriesLoader(client: dataClient)
    
    private(set) lazy var storiesViewModel = StoriesViewModel(
        storiesLoader: storiesLoader,
        fileManager: fileManager
    )
    
    private(set) lazy var storiesAnimationHandler = StoriesAnimationHandler(storiesHolder: storiesViewModel)
    
    private let cameraCore = AVCameraCore()
    private lazy var photoTaker = AVPhotoTaker(device: cameraCore)
    private lazy var videoRecorder = AVVideoRecorder(device: cameraCore)
    private lazy var cameraAuxiliary = AVCameraAuxiliary(camera: cameraCore)
    private(set) lazy var camera = DefaultCamera(
        cameraCore: cameraCore,
        photoTaker: photoTaker,
        videoRecorder: videoRecorder,
        cameraAuxiliary: cameraAuxiliary
    )
    
    let cameraAuthorizationTracker = AVCaptureDeviceAuthorizationTracker(mediaType: .video)
    let microphoneAuthorizationTracker = AVCaptureDeviceAuthorizationTracker(mediaType: .audio)
}

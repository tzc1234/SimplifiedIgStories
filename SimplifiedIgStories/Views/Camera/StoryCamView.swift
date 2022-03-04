//
//  StoryCamView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import SwiftUI

final class StoryCamGlobal: ObservableObject {
    @Published var cameraSelection: SwiftyCamViewController.CameraSelection = .rear
    @Published var enableVideoRecordBtn = false
    @Published var flashMode: FlashMode = .off
    
    @Published var shouldPhotoTake = false
    var lastTakenImage: UIImage?
    @Published var photoDidTake = false
    
    @Published var videoRecordingStatus: VideoRecordingStatus = .none
    var lastVideoUrl: URL?
    @Published var videoDidRecord = false
    
    enum FlashMode {
        case on, off, auto
        
        var swiftyCamFlashMode: SwiftyCamViewController.FlashMode {
            switch self {
            case .auto: return .auto
            case .on: return .on
            case .off: return .off
            }
        }
        
        var systemImageName: String {
            switch self {
            case .auto: return "bolt.badge.a.fill"
            case .on: return "bolt.fill"
            case .off: return  "bolt.slash.fill"
            }
        }
    }
    
    enum VideoRecordingStatus {
        case none, start, stop
    }
}

struct StoryCamView: View {
    @StateObject private var storyCamGlobal = StoryCamGlobal()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                StorySwiftyCamControllerRepresentable(storyCamGlobal: storyCamGlobal)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        closeButton
                        Spacer()
                        flashButton
                        Spacer()
                        Color.clear.frame(width: 45)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    HStack(alignment: .bottom, spacing: 0) {
                        Spacer()
                        videoRecordButton
                        Spacer()
                    }
                    
                    HStack(alignment: .bottom, spacing: 0) {
                        Spacer()
                        changeCameraButton
                    }
                    .padding(.horizontal, 20)
                    
                }
                .padding(.vertical, 20)
               
                if storyCamGlobal.photoDidTake, let uiImage = storyCamGlobal.lastTakenImage {
                    StoryPreview(uiImage: uiImage) {
                        storyCamGlobal.photoDidTake = false
                    }
                }
                
                if storyCamGlobal.videoDidRecord, let url = storyCamGlobal.lastVideoUrl {
                    StoryPreview(videoUrl: url) {
                        storyCamGlobal.videoDidRecord = false
                    }
                }
                
            }
            .statusBar(hidden: true)
            
        }
        
    }
}

struct StoryCamView_Previews: PreviewProvider {
    static var previews: some View {
        StoryCamView().background(.green)
    }
}

// MARK: components
extension StoryCamView {
    var closeButton: some View {
        Button{
            print("close.")
        } label: {
            ZStack {
                Color.clear.frame(width: 45, height: 45)
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
            }
            .contentShape(Rectangle())
        }
        .opacity(storyCamGlobal.videoRecordingStatus == .start ? 0 : 1)
    }
    
    var flashButton: some View {
        Button {
            toggleFlashMode()
        } label: {
            ZStack {
                Color.clear.frame(width: 45, height: 45)
                Image(systemName: storyCamGlobal.flashMode.systemImageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
            }
        }
        .opacity(storyCamGlobal.videoRecordingStatus == .start ? 0 : 1)
    }
    
    var videoRecordButton: some View {
        VideoRecordButton() {
            storyCamGlobal.shouldPhotoTake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                storyCamGlobal.shouldPhotoTake = false
            }
        } longPressingAction: { isPressing in
            storyCamGlobal.videoRecordingStatus = isPressing ? .start : .stop
        }
        .allowsHitTesting(storyCamGlobal.enableVideoRecordBtn)
    }
    
    var changeCameraButton: some View {
        Button {
            storyCamGlobal.cameraSelection = storyCamGlobal.cameraSelection == .rear ? .front : .rear
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
        }
        .opacity(storyCamGlobal.videoRecordingStatus == .start ? 0 : 1)
    }
}

// MARK: functions
extension StoryCamView {
    func toggleFlashMode() {
        switch storyCamGlobal.flashMode {
        case .auto:
            storyCamGlobal.flashMode = .off
        case .on:
            storyCamGlobal.flashMode = .auto
        case .off:
            storyCamGlobal.flashMode = .on
        }
    }
}

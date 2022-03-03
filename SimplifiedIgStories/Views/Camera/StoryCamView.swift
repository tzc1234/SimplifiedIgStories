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
    @Published var flashMode: StoryCamView.FlashMode = .off
    @Published var shouldPhotoTake = false
    
    var lastTakenImage: UIImage?
    @Published var photoDidTake = false
}

struct StoryCamView: View {
    @StateObject private var storyCamGlobal = StoryCamGlobal()
    
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
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                StorySwiftyCamControllerRepresentable(storyCamGlobal: storyCamGlobal)
//                Color.green
                
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
                
            }
            .statusBar(hidden: true)
            .sheet(isPresented: $storyCamGlobal.photoDidTake) {
                if let uiImage = storyCamGlobal.lastTakenImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
            }
            
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
    }
    
    var videoRecordButton: some View {
        VideoRecordButton() {
            storyCamGlobal.shouldPhotoTake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                storyCamGlobal.shouldPhotoTake = false
            }
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

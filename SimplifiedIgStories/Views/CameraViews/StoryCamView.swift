//
//  StoryCamView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import SwiftUI

struct StoryCamView: View {
    @StateObject private var vm = StoryCamViewModel()
    
    let tapCloseAction: (() -> Void)?
    
    init(tapCloseAction: (() -> Void)? = nil) {
        self.tapCloseAction = tapCloseAction
    }
    
    var body: some View {
        ZStack {
            if vm.camPermGranted && vm.microphonePermGranted {
                StorySwiftyCamControllerRepresentable(storyCamViewModel: vm)
            } else {
                StoryCamPermissionView(storyCamViewModel: vm)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    closeButton
                    Spacer()
                    if vm.camPermGranted && vm.microphonePermGranted {
                        flashButton
                    }
                    Spacer()
                    Color.clear.frame(width: 45)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                HStack(alignment: .bottom, spacing: 0) {
                    Spacer()
                    if vm.camPermGranted && vm.microphonePermGranted {
                        videoRecordButton
                    }
                    Spacer()
                }
                
                HStack(alignment: .bottom, spacing: 0) {
                    Spacer()
                    if vm.camPermGranted && vm.microphonePermGranted {
                        changeCameraButton
                    }
                }
                .padding(.horizontal, 20)
                
            }
            .padding(.vertical, 20)
            
            if vm.photoDidTake, let uiImage = vm.lastTakenImage {
                StoryPreview(uiImage: uiImage) { vm.photoDidTake = false }
            } else if vm.videoDidRecord, let url = vm.lastVideoUrl {
                StoryPreview(videoUrl: url) { vm.videoDidRecord = false }
            }
            
        }
        .statusBar(hidden: true)
        .onAppear {
            vm.requestPermission()
        }
        
    }
}

struct StoryCamView_Previews: PreviewProvider {
    static var previews: some View {
        StoryCamView()
    }
}

// MARK: components
extension StoryCamView {
    private var closeButton: some View {
        Button{
            tapCloseAction?()
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
        .opacity(vm.videoRecordingStatus == .start ? 0 : 1)
    }
    
    private var flashButton: some View {
        Button {
            toggleFlashMode()
        } label: {
            ZStack {
                Color.clear.frame(width: 45, height: 45)
                Image(systemName: vm.flashMode.systemImageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
            }
        }
        .opacity(vm.videoRecordingStatus == .start ? 0 : 1)
    }
    
    private var videoRecordButton: some View {
        VideoRecordButton() {
            vm.shouldPhotoTake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                vm.shouldPhotoTake = false
            }
        } longPressingAction: { isPressing in
            vm.videoRecordingStatus = isPressing ? .start : .stop
        }
        .allowsHitTesting(vm.enableVideoRecordBtn)
    }
    
    private var changeCameraButton: some View {
        Button {
            vm.cameraSelection = vm.cameraSelection == .rear ? .front : .rear
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
        }
        .opacity(vm.videoRecordingStatus == .start ? 0 : 1)
    }
}

// MARK: functions
extension StoryCamView {
    private func toggleFlashMode() {
        switch vm.flashMode {
        case .auto:
            vm.flashMode = .off
        case .on:
            vm.flashMode = .auto
        case .off:
            vm.flashMode = .on
        }
    }
}

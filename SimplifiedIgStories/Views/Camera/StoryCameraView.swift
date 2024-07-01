//
//  StoryCameraView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import SwiftUI

struct StoryCameraView: View {
    @EnvironmentObject private var actionHandler: HomeUIActionHandler
    @ObservedObject var vm: StoryCameraViewModel
    
    var body: some View {
        ZStack {
            if vm.arePermissionsGranted {
                AVCaptureVideoPreviewRepresentable(storyCamViewModel: vm)
            } else {
                StoryCamPermissionView(storyCamViewModel: vm)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    closeButton
                    Spacer()
                    flashButton
                    Spacer()
                    Color.clear.frame(width: 45)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                
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
            
            if vm.showPhotoPreview, let uiImage = vm.lastTakenImage {
                StoryPreview(uiImage: uiImage) {
                    vm.showPhotoPreview = false
                } postBtnAction: {
                    actionHandler.postImageAction?(uiImage)
                }
            } else if vm.showVideoPreview, let url = vm.lastVideoUrl {
                StoryPreview(videoUrl: url) {
                    vm.showVideoPreview = false
                } postBtnAction: {
                    actionHandler.postVideoAction?(url)
                }
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            vm.checkPermissions()
        }
        .onChange(of: vm.arePermissionsGranted) { isGranted in
            if isGranted {
                vm.startSession()
            }
        }
        .onDisappear {
            print("StoryCamView disappear")
        }
    }
}

struct StoryCamView_Previews: PreviewProvider {
    static var previews: some View {
        StoryCameraView(vm: StoryCameraViewModel(camera: DefaultCamera.dummy))
    }
}

// MARK: components
extension StoryCameraView {
    private var closeButton: some View {
        Button{
            actionHandler.tapStoryCameraCloseAction?()
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
    
    @ViewBuilder private var flashButton: some View {
        if vm.arePermissionsGranted {
            Button {
                toggleFlashMode()
            } label: {
                ZStack {
                    Color.clear.frame(width: 45, height: 45)
                    Image(systemName: flashModeImageName)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                }
            }
            .opacity(vm.videoRecordingStatus == .start ? 0 : 1)
        }
    }
    
    @ViewBuilder private var videoRecordButton: some View {
        if vm.arePermissionsGranted {
            VideoRecordButton() {
                vm.shouldPhotoTake = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    vm.shouldPhotoTake = false
                }
            } longPressingAction: { isPressing in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    vm.videoRecordingStatus = isPressing ? .start : .stop
                }
            }
            .allowsHitTesting(vm.enableVideoRecordBtn)
        }
    }
    
    @ViewBuilder private var changeCameraButton: some View {
        if vm.arePermissionsGranted {
            Button {
                vm.switchCamera()
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
}

// MARK: computed variables
extension StoryCameraView {
    private var flashModeImageName: String {
        switch vm.flashMode {
        case .auto: return "bolt.badge.a.fill"
        case .on:   return "bolt.fill"
        case .off:  return "bolt.slash.fill"
        }
    }
}

// MARK: private functions
extension StoryCameraView {
    private func toggleFlashMode() {
        switch vm.flashMode {
        case .auto: vm.flashMode = .off
        case .on:   vm.flashMode = .auto
        case .off:  vm.flashMode = .on
        }
    }
}

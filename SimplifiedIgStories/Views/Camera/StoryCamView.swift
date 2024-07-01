//
//  StoryCamView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import SwiftUI

struct StoryCamView: View {
    @StateObject private var vm: StoryCamViewModel
    
    let postImageAction: ((UIImage) -> Void)
    let postVideoAction: ((URL) -> Void)
    let tapCloseAction: (() -> Void)
    
    init(postImageAction: @escaping (UIImage) -> Void,
         postVideoAction: @escaping (URL) -> Void,
         tapCloseAction: @escaping () -> Void) {
        let camera = AVCamera()
        let photoTaker = AVPhotoTaker(device: camera)
        let videoRecorder = AVVideoRecorder(device: camera)
        let cameraAuxiliary = AVCameraAuxiliary(camera: camera)
        
        let fullFunctionsCamera = DefaultFullFunctionsCamera(
            camera: camera,
            photoTaker: photoTaker,
            videoRecorder: videoRecorder,
            cameraAuxiliary: cameraAuxiliary
        )
        
        let vm = StoryCamViewModel(camera: fullFunctionsCamera)
        self._vm = StateObject(wrappedValue: vm)
        
        self.postImageAction = postImageAction
        self.postVideoAction = postVideoAction
        self.tapCloseAction = tapCloseAction
    }
    
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
                    postImageAction(uiImage)
                }
            } else if vm.showVideoPreview, let url = vm.lastVideoUrl {
                StoryPreview(videoUrl: url) {
                    vm.showVideoPreview = false
                } postBtnAction: {
                    postVideoAction(url)
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
        StoryCamView(postImageAction: {_ in }, postVideoAction: {_ in }, tapCloseAction: {})
    }
}

// MARK: components
extension StoryCamView {
    private var closeButton: some View {
        Button{
            tapCloseAction()
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
extension StoryCamView {
    private var flashModeImageName: String {
        switch vm.flashMode {
        case .auto: return "bolt.badge.a.fill"
        case .on:   return "bolt.fill"
        case .off:  return "bolt.slash.fill"
        }
    }
}

// MARK: private functions
extension StoryCamView {
    private func toggleFlashMode() {
        switch vm.flashMode {
        case .auto: vm.flashMode = .off
        case .on:   vm.flashMode = .auto
        case .off:  vm.flashMode = .on
        }
    }
}

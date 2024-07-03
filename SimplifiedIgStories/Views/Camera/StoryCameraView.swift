//
//  StoryCameraView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import SwiftUI

struct StoryCameraView: View {
    @EnvironmentObject private var actionHandler: HomeUIActionHandler
    @ObservedObject var viewModel: StoryCameraViewModel
    
    var body: some View {
        ZStack {
            if viewModel.arePermissionsGranted {
                AVCaptureVideoPreviewRepresentable(storyCamViewModel: viewModel)
            } else {
                StoryCameraPermissionView(viewModel: viewModel)
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
            
            if viewModel.showPhotoPreview, let image = viewModel.lastTakenImage {
                StoryPreview(uiImage: image, backBtnAction: {
                    viewModel.showPhotoPreview = false
                }, postBtnAction: {
                    actionHandler.postImageAction?(image)
                })
            } else if viewModel.showVideoPreview, let url = viewModel.lastVideoURL {
                StoryPreview(videoUrl: url, backBtnAction: {
                    viewModel.showVideoPreview = false
                }, postBtnAction: {
                    actionHandler.postVideoAction?(url)
                })
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            viewModel.checkPermissions()
        }
        .onChange(of: viewModel.arePermissionsGranted) { isGranted in
            if isGranted {
                viewModel.startSession()
            }
        }
        .onDisappear {
            print("StoryCamView disappear")
        }
    }
}

struct StoryCamView_Previews: PreviewProvider {
    static var previews: some View {
        StoryCameraView(viewModel: StoryCameraViewModel(
            camera: DefaultCamera.dummy,
            cameraAuthorizationTracker: AVCaptureDeviceAuthorizationTracker(mediaType: .video),
            microphoneAuthorizationTracker: AVCaptureDeviceAuthorizationTracker(mediaType: .audio)
        ))
    }
}

// MARK: components
extension StoryCameraView {
    private var closeButton: some View {
        Button{
            actionHandler.closeStoryCameraView()
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
        .opacity(viewModel.isVideoRecording == true ? 0 : 1)
    }
    
    @ViewBuilder private var flashButton: some View {
        if viewModel.arePermissionsGranted {
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
            .opacity(viewModel.isVideoRecording == true ? 0 : 1)
        }
    }
    
    @ViewBuilder private var videoRecordButton: some View {
        if viewModel.arePermissionsGranted {
            VideoRecordButton() {
                viewModel.takePhoto()
            } longPressingAction: { isPressing in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.isVideoRecording = isPressing ? true : false
                }
            }
            .allowsHitTesting(viewModel.enableVideoRecordButton)
        }
    }
    
    @ViewBuilder private var changeCameraButton: some View {
        if viewModel.arePermissionsGranted {
            Button {
                viewModel.switchCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
            }
            .opacity(viewModel.isVideoRecording == true ? 0 : 1)
        }
    }
}

// MARK: computed variables
extension StoryCameraView {
    private var flashModeImageName: String {
        switch viewModel.flashMode {
        case .auto: return "bolt.badge.a.fill"
        case .on:   return "bolt.fill"
        case .off:  return "bolt.slash.fill"
        }
    }
}

// MARK: private functions
extension StoryCameraView {
    private func toggleFlashMode() {
        switch viewModel.flashMode {
        case .auto: viewModel.flashMode = .off
        case .on:   viewModel.flashMode = .auto
        case .off:  viewModel.flashMode = .on
        }
    }
}

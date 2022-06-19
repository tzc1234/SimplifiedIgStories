//
//  StoryCamView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import SwiftUI

struct StoryCamView: View {
    @StateObject private var vm = StoryCamViewModel(camManager: AVCamManager())
    @State private var showStatusBar = true
    
    let tapCloseAction: (() -> Void)?
    
    init(tapCloseAction: (() -> Void)? = nil) {
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
            
            if vm.photoDidTake, let uiImage = vm.lastTakenImage {
                StoryPreview(uiImage: uiImage) { vm.photoDidTake = false }
            } else if vm.videoDidRecord, let url = vm.lastVideoUrl {
                StoryPreview(videoUrl: url) { vm.videoDidRecord = false }
            }
        }
        .statusBar(hidden: showStatusBar)
        .onAppear {
            vm.checkPermissions()
        }
        .onChange(of: vm.arePermissionsGranted) { isGranted in
            if isGranted {
                vm.setupSession()
            }
        }
        .onDisappear {
            showStatusBar = false
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
                vm.camPosition = vm.camPosition == .back ? .front : .back
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
    
    private var flashModeImageName: String {
        switch vm.flashMode {
        case .auto: return "bolt.badge.a.fill"
        case .on: return "bolt.fill"
        case .off: return  "bolt.slash.fill"
        @unknown default: return ""
        }
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
        @unknown default:
            break
        }
    }
}

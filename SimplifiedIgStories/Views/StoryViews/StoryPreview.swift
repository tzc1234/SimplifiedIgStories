//
//  StoryPreview.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import SwiftUI
import AVKit

struct StoryPreview: View {
    @EnvironmentObject private var vm: StoriesViewModel
    
    @State private var isLoading = false
    @State private var showNoticeLabel = false
    @State private var showAlert = false
    @State private var noticeMsg = ""
    
    @State private var player: AVPlayer?
    
    let uiImage: UIImage?
    let videoUrl: URL?
    let backBtnAction: (() -> Void)
    
    init(uiImage: UIImage? = nil, videoUrl: URL? = nil, backBtnAction: @escaping (() -> Void)) {
        self.uiImage = uiImage
        self.videoUrl = videoUrl
        self.backBtnAction = backBtnAction
    }
    
    var body: some View {
        ZStack {
            photoView
            videoView
            
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 0) {
                    backBtn
                    Spacer()
                    saveBtn
                }
                .padding(.horizontal, 12)
                
                Spacer()
                
                HStack(alignment: .bottom, spacing: 0) {
                    Spacer()
                    postBtn
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 20)
            
            if isLoading {
                LoadingView()
            }
         
            noticeLabel
        }
        .onAppear {
            if let videoUrl = videoUrl {
                player = AVPlayer(url: videoUrl)
            }
        }
        
    }
}

struct StoryPreview_Previews: PreviewProvider {
    static var previews: some View {
        StoryPreview(backBtnAction: {})
            .environmentObject(StoriesViewModel())
    }
}

// MARK: components
extension StoryPreview {
    @ViewBuilder private var photoView: some View {
        if let uiImage = uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        }
    }
    
    @ViewBuilder private var videoView: some View {
        if player != nil {
            AVPlayerControllerRepresentable(
                shouldLoop: true,
                player: $player
            )
        }
    }
    
    private var backBtn: some View {
        Button {
            showAlert.toggle()
        } label: {
            Image(systemName: "chevron.backward")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .scaleEffect(0.5)
                .background(
                    Circle().foregroundColor(.darkGray)
                        .frame(width: 45, height: 45)
                )
                .frame(width: 45, height: 45)
        }
        .alert("Discard media?", isPresented: $showAlert) {
            Button("Discard", role: .destructive) {
                backBtnAction()
            }
            Button("Cancel", role: .cancel, action: {})
        } message: {
            Text("If you go back now, you will lose it.")
        }
    }
    
    private var saveBtn: some View {
        Button {
            saveToAlbum()
        } label: {
            Image(systemName: "arrow.down.to.line")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .scaleEffect(0.5)
                .background(
                    Circle().foregroundColor(.darkGray)
                        .frame(width: 45, height: 45)
                )
        }
        .frame(width: 45, height: 45)
    }
    
    private var postBtn: some View {
        Button {
            postStoryPortion()
        } label: {
            Text("Post")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 15)
                .padding(.horizontal, 50)
                .background(
                    Capsule().foregroundColor(.darkGray)
                )
        }
    }
    
    private var noticeLabel: some View {
        NoticeLabel(message: noticeMsg)
            .opacity(showNoticeLabel ? 1 : 0)
            .animation(.easeInOut, value: showNoticeLabel)
    }
}

// MARK: functions
extension StoryPreview {
    private func showNoticeMsg(_ msg: String) {
        noticeMsg = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showNoticeLabel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showNoticeLabel = false
            }
        }
    }
    
    private func saveToAlbum() {
        let completion: ImageVideoSaveCompletion = { result in
            switch result {
            case .success(_):
                isLoading = false
                showNoticeMsg("Saved.")
            case .failure(let imageVideoSaveErr):
                switch imageVideoSaveErr {
                case .noAddPhotoPermission:
                    isLoading = false
                    showNoticeMsg("Couldn't save. No add photo permission.")
                case .saveError(let err):
                    isLoading = false
                    showNoticeMsg("ERROR: \(err.localizedDescription)")
                }
            }
        }
        
        if let uiImage = uiImage {
            let imageSaver = ImageSaver(completion: completion)
            isLoading = true
            imageSaver.saveImageToAlbum(uiImage)
        } else if let videoUrl = videoUrl {
            let videoSaver = VideoSaver(completion: completion)
            isLoading = true
            videoSaver.saveVideoToAlbum(videoUrl)
        }
    }
    
    private func postStoryPortion() {
        guard let yourStoryIdx = vm.yourStoryIdx else { return }
        
        var portions = vm.stories[yourStoryIdx].portions
        
        // *** In real environment, the photo or video recorded should be uploaded to server side,
        // this is a demo app, however, storing them into temp directory for displaying IG story animation.
        if let uiImage = uiImage,
            let imageUrl = LocalFileManager.instance.saveImageToTemp(image: uiImage)
        {
            // Just append a new Portion instance to current user's potion array.
            portions.append(
                Portion(id: vm.lastPortionId + 1, imageUrl: imageUrl)
            )
            vm.stories[yourStoryIdx].portions = portions
            vm.stories[yourStoryIdx].lastUpdate = Date().timeIntervalSince1970
        } else if let videoUrl = videoUrl { // Similar process in video case.
            let asset = AVAsset(url: videoUrl)
            let duration = asset.duration
            let durationSeconds = CMTimeGetSeconds(duration)
            
            portions.append(
                Portion(id: vm.lastPortionId + 1, videoDuration: durationSeconds, videoUrlFromCam: videoUrl)
            )
            vm.stories[yourStoryIdx].portions = portions
            vm.stories[yourStoryIdx].lastUpdate = Date().timeIntervalSince1970
        }
        
        vm.toggleStoryCamView()
    }
}

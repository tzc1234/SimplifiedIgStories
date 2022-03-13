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
    @State private var showSaved = false
    @State private var showAlert = false
    
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
         
            savedLabel
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
            if uiImage != nil {
                saveToAlbum(uiImage)
            } else {
                saveToAlbum(videoUrl)
            }
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
    
    private var savedLabel: some View {
        Text("Saved")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10).foregroundColor(.darkGray)
            )
            .opacity(showSaved ? 1 : 0)
            .animation(.easeIn, value: showSaved)
    }
}

// MARK: functions
extension StoryPreview {
    private func saveToAlbum<T>(_ object: T) {
        let completeAction = {
            isLoading = false
            showSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showSaved = false
            }
        }
        
        if object is UIImage?, let image = object as? UIImage {
            let imageSaver = ImageSaver(saveCompletedAction: completeAction)
            isLoading = true
            imageSaver.saveImageToAlbum(image)
        } else if object is URL?, let url = object as? URL {
            let videoSaver = VideoSaver(saveCompletedAction: completeAction)
            isLoading = true
            videoSaver.saveVideoToAlbum(url)
        } else {
            print("File Not Support!")
        }
    }
}

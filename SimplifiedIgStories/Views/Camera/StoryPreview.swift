//
//  StoryPreview.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import SwiftUI
import AVKit

struct StoryPreview: View {
    @State private var isLoading = false
    @State private var showNoticeLabel = false
    @State private var showAlert = false
    @State private var noticeMsg = ""
    @State private var player: AVPlayer?
    
    let uiImage: UIImage?
    let videoUrl: URL?
    let backBtnAction: (() -> Void)
    let postBtnAction: (() -> Void)
    
    init(uiImage: UIImage,
         backBtnAction: @escaping (() -> Void),
         postBtnAction: @escaping (() -> Void)) {
        self.init(uiImage: uiImage, videoUrl: nil, backBtnAction: backBtnAction, postBtnAction: postBtnAction)
    }
    
    init(videoUrl: URL,
         backBtnAction: @escaping (() -> Void),
         postBtnAction: @escaping (() -> Void)) {
        self.init(uiImage: nil, videoUrl: videoUrl, backBtnAction: backBtnAction, postBtnAction: postBtnAction)
    }
    
    private init(uiImage: UIImage?,
                 videoUrl: URL?,
                 backBtnAction: @escaping (() -> Void),
                 postBtnAction: @escaping (() -> Void)) {
        self.uiImage = uiImage
        self.videoUrl = videoUrl
        self.backBtnAction = backBtnAction
        self.postBtnAction = postBtnAction
    }
    
    var body: some View {
        ZStack {
            photoView
            videoView
            
            VStack {
                HStack {
                    backBtn
                    Spacer()
                    saveBtn
                }
                .padding(.horizontal, 12)
                
                Spacer()
                
                HStack {
                    Spacer()
                    postBtn
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
            .frame(width: .screenWidth)
            .padding(.vertical, 20)
            
            LoadingView()
                .opacity(isLoading ? 1 : 0)
            
            noticeLabel
        }
        .onAppear {
            if let videoUrl {
                player = AVPlayer(url: videoUrl)
            }
        }
    }
}

struct StoryPreview_Previews: PreviewProvider {
    static var previews: some View {
        StoryPreview(uiImage: UIImage(), backBtnAction: {}, postBtnAction: {})
    }
}

// MARK: components
extension StoryPreview {
    @ViewBuilder 
    private var photoView: some View {
        if let uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        }
    }
    
    @ViewBuilder 
    private var videoView: some View {
        if player != nil {
            AVPlayerControllerRepresentable(
                shouldLoop: true,
                player: player
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
            Button("Discard", role: .destructive, action: backBtnAction)
            Button("Cancel", role: .cancel, action: {})
        } message: {
            Text("If you go back now, you will lose it.")
        }
    }
    
    private var saveBtn: some View {
        Button(action: saveToAlbum) {
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
        Button(action: postBtnAction) {
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

// MARK: helpers
extension StoryPreview {
    private func saveToAlbum() {
        Task { @MainActor in
            isLoading = true
            
            var successMessage: String?
            if let data = uiImage?.jpegData(compressionQuality: 1) {
                do {
                    try await LocalMediaSaver(store: PHPPhotoMediaStore()).saveImageData(data)
                    successMessage = "Saved."
                } catch MediaSaverError.noPermission {
                    successMessage = "Couldn't save. No add photo permission."
                } catch {
                    successMessage = "Save failed."
                }
            } else if let videoUrl = videoUrl {
                do {
                    try await LocalMediaSaver(store: PHPPhotoMediaStore()).saveVideo(by: videoUrl)
                    successMessage = "Saved."
                } catch MediaSaverError.noPermission {
                    successMessage = "Couldn't save. No add photo permission."
                } catch {
                    successMessage = "Save failed."
                }
            }
            
            isLoading = false
            showNotice(message: successMessage)
        }
    }
    
    private func showNotice(message: String?) {
        guard let message else { return }
        
        noticeMsg = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showNoticeLabel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showNoticeLabel = false
            }
        }
    }
}

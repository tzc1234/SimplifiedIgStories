//
//  StoryPreview.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import SwiftUI
import AVKit

struct StoryPreview: View {
    @ObservedObject var viewModel: StoryPreviewViewModel = .init(mediaSaver: LocalMediaSaver(store: PHPPhotoMediaStore()))
    
    @State private var showNoticeLabel = false
    @State private var showAlert = false
    @State private var player: AVPlayer?
    
    let image: UIImage?
    let videoURL: URL?
    let backBtnAction: (() -> Void)
    let postBtnAction: (() -> Void)
    
    init(image: UIImage,
         backBtnAction: @escaping (() -> Void),
         postBtnAction: @escaping (() -> Void)) {
        self.init(image: image, videoURL: nil, backBtnAction: backBtnAction, postBtnAction: postBtnAction)
    }
    
    init(videoURL: URL,
         backBtnAction: @escaping (() -> Void),
         postBtnAction: @escaping (() -> Void)) {
        self.init(image: nil, videoURL: videoURL, backBtnAction: backBtnAction, postBtnAction: postBtnAction)
    }
    
    private init(image: UIImage?,
                 videoURL: URL?,
                 backBtnAction: @escaping (() -> Void),
                 postBtnAction: @escaping (() -> Void)) {
        self.image = image
        self.videoURL = videoURL
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
                .opacity(viewModel.isLoading ? 1 : 0)
            
            noticeLabel
        }
        .onAppear {
            if let videoURL {
                player = AVPlayer(url: videoURL)
            }
        }
    }
}

extension StoryPreview {
    @ViewBuilder 
    private var photoView: some View {
        if let image {
            Image(uiImage: image)
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
        Button {
            if let image {
                Task { @MainActor in
                    await viewModel.saveToAlbum(image: image)
                }
            } else if let videoURL {
                Task { @MainActor in
                    await viewModel.saveToAlbum(videoURL: videoURL)
                }
            }
            
            showNotice()
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
        NoticeLabel(message: viewModel.message)
            .opacity(showNoticeLabel ? 1 : 0)
            .animation(.easeInOut, value: showNoticeLabel)
    }
    
    private func showNotice() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showNoticeLabel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showNoticeLabel = false
            }
        }
    }
}

struct StoryPreview_Previews: PreviewProvider {
    static var previews: some View {
        StoryPreview(image: UIImage(), backBtnAction: {}, postBtnAction: {})
    }
}

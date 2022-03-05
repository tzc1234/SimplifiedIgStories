//
//  StoryPreview.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import SwiftUI

struct StoryPreview: View {
    @State private var isLoading = false
    @State private var showSaved = false
    @State private var showAlert = false
    
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
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
            
            if let videoUrl = videoUrl {
                AVPlayerControllerRepresentable(videoUrl: videoUrl)
            }
            
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
                .opacity(showSaved ? 1 : 0)
                .animation(.easeIn, value: showSaved)
        }
        
    }
}

struct StoryPreview_Previews: PreviewProvider {
    static var previews: some View {
        StoryPreview(backBtnAction: {})
    }
}

// MARK: components
extension StoryPreview {
    var backBtn: some View {
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
    
    var saveBtn: some View {
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
    
    var postBtn: some View {
        Button {
            print("Post.")
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
    
    var savedLabel: some View {
        Text("Saved")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10).foregroundColor(.darkGray)
            )
    }
}

// MARK: functions
extension StoryPreview {
    func saveToAlbum<T>(_ object: T) {
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

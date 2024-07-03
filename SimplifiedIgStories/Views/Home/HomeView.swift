//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var handler = HomeUIActionHandler()
    
    @ObservedObject var storiesViewModel: StoriesViewModel
    let getStoryIconsView: () -> StoryIconsView
    let getStoryContainer: () -> StoryContainer
    let getStoryCameraView: () -> StoryCameraView
    
    var body: some View {
        ZStack {
            HStack(spacing: 0.0) {
                storyCameraView
                
                NavigationView {
                    VStack {
                        getStoryIconsView()
                            .onPreferenceChange(IdFramePreferenceKey.self) { idFrameDict in
                                handler.storyIconFrameDict = idFrameDict
                            }
                        
                        Spacer()
                    }
                    .navigationTitle("Stories")
                }
                .navigationViewStyle(.stack)
            }
            
            storyContainer
        }
        .frame(width: .screenWidth)
        .environmentObject(handler)
        .task {
            await storiesViewModel.fetchStories()
        }
        .onAppear {
            handler.postMedia = { media in
                switch media {
                case let .image(image):
                    storiesViewModel.postStoryPortion(image: image)
                case let .video(url):
                    storiesViewModel.postStoryPortion(videoUrl: url)
                }
                
                handler.closeStoryCameraView()
            }
        }
    }
}

// MARK: components
extension HomeView {
    private var storyCameraView: some View {
        ZStack {
            if handler.isStoryCameraViewShown {
                getStoryCameraView()
                    .frame(width: .screenWidth)
            }
        }
        .ignoresSafeArea()
    }
    
    private var storyContainer: some View {
        GeometryReader { geo in
            if handler.isContainerShown {
                let iconFrame = handler.currentIconFrame
                let offsetX = -(geo.size.width / 2 - iconFrame.midX)
                let offsetY = iconFrame.minY - geo.safeAreaInsets.top
                getStoryContainer()
                    .zIndex(1.0)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .openAppImitationTransition(scale: iconFrame.height / .screenHeight, offsetX: offsetX, offsetY: offsetY)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            storiesViewModel: .preview,
            getStoryIconsView: {
                StoryIconsView(animationHandler: .preview)
            },
            getStoryContainer: {
                StoryContainer(
                    animationHandler: .preview,
                    getStoryView: { _ in .preview }
                )
            }, 
            getStoryCameraView: {
                StoryCameraView(viewModel: StoryCameraViewModel(
                    camera: DefaultCamera.dummy,
                    cameraAuthorizationTracker: AVCaptureDeviceAuthorizationTracker(mediaType: .video),
                    microphoneAuthorizationTracker: AVCaptureDeviceAuthorizationTracker(mediaType: .audio)
                ), getStoryPreview: { media, backBtnAction, postBtnAction in
                    StoryPreview(
                        viewModel: StoryPreviewViewModel(mediaSaver: DummyMediaSaver()),
                        media: media,
                        backBtnAction: backBtnAction,
                        postBtnAction: postBtnAction
                    )
                })
            }
        )
    }
}

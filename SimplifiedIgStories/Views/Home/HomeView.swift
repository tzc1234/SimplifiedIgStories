//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var handler = HomeUIActionHandler()
    @StateObject var storiesViewModel: StoriesViewModel
    
    var body: some View {
        ZStack {
            HStack(spacing: 0.0) {
                storyCamView
                
                NavigationView {
                    VStack {
                        StoryIconsView(vm: storiesViewModel)
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
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(storiesViewModel: .preview)
    }
}

// MARK: components
extension HomeView {
    private var storyCamView: some View {
        ZStack {
            if handler.showStoryCamView {
                StoryCamView { image in
                    storiesViewModel.postStoryPortion(image: image)
                    showHideStoryCamView()
                } postVideoAction: { url in
                    storiesViewModel.postStoryPortion(videoUrl: url)
                    showHideStoryCamView()
                } tapCloseAction: {
                    showHideStoryCamView()
                }
                .frame(width: .screenWidth)
            }
        }
        .ignoresSafeArea()
    }
    
    private var storyContainer: some View {
        GeometryReader { geo in
            if handler.showContainer {
                let iconFrame = handler.currentIconFrame
                let offsetX = -(geo.size.width / 2 - iconFrame.midX)
                let offsetY = iconFrame.minY - geo.safeAreaInsets.top
                StoryContainer(vm: storiesViewModel)
                    .zIndex(1.0)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .openAppImitationTransition(scale: iconFrame.height / .screenHeight, offsetX: offsetX, offsetY: offsetY)
            }
        }
    }
}

// MARK: helper functions
extension HomeView {
    private func showHideStoryCamView() {
        withAnimation(.default) {
            handler.showStoryCamView.toggle()
        }
    }
}

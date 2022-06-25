//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var vm = StoriesViewModel()
    
    var body: some View {
        ZStack {
            GeometryReader { _ in
                HStack(spacing: 0.0) {
                    storyCamView
                
                    NavigationView {
                        VStack {
                            StoryIconsView(stories: vm.stories, onTapAction: vm.tapStoryIcon)
                            Spacer()
                        }
                        .navigationTitle("Stories")
                        .onPreferenceChange(IdFramePreferenceKey.self) { idFrameDict in
                            vm.storyIconFrames = idFrameDict
                        }
                    }
                    .frame(width: .screenWidth)
                    .navigationViewStyle(.stack)
                }
            }
            .offset(x: vm.showStoryCamView ? 0.0 : -.screenWidth)
            
            storyContainer
        }
        .environmentObject(vm)
        .task {
            await vm.fetchStories()
        }
        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(StoriesViewModel())
    }
}

// MARK: components
extension HomeView {
    private var storyCamView: some View {
        ZStack {
            if vm.showStoryCamView {
                StoryCamView(tapCloseAction: vm.toggleStoryCamView)
            }
        }
        .ignoresSafeArea()
        .frame(width: .screenWidth)
    }
    
    private var storyContainer: some View {
        GeometryReader { geo in
            let iconFrame: CGRect = vm.currentStoryIconFrame
            let offsetX = -(geo.size.width / 2 - iconFrame.midX)
            let offsetY = iconFrame.minY - geo.safeAreaInsets.top
            if vm.showContainer {
                StoryContainer()
                    .zIndex(1.0)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .openAppLikeTransition(sacle: iconFrame.height / .screenHeight, offestX: offsetX, offsetY: offsetY)
            }
        }
    }
}

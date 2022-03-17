//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var vm = StoriesViewModel()
    
    private let titleHeight = 44.0
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 0.0) {
                storyCamView
                
                ZStack {
                    VStack(alignment: .leading, spacing: 0.0) {
                        titleView
                        StoryIconsView(stories: vm.stories, onTapAction: vm.tapStoryIcon)
                        Spacer()
                    }
                    
                    storyContainer(geo: geo)
                }
                .frame(width: .screenWidth)
                
            }
            .offset(x: vm.showStoryCamView ? 0.0 : -.screenWidth)
            .environmentObject(vm)
            .onPreferenceChange(IdFramePreferenceKey.self) { idFrameDict in
                vm.storyIconFrames = idFrameDict
            }
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
        .frame(width: .screenWidth)
    }
    
    private var titleView: some View {
        Text("Stories")
            .font(.title)
            .bold()
            .frame(height: titleHeight, alignment: .leading)
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder private func storyContainer(geo: GeometryProxy) -> some View {
        let frame = vm.currentStoryIconFrame
        let offsetX = -(geo.size.width / 2 - frame.midX)
        let offsetY = titleHeight + ((frame.height - frame.width / 1.5) / 2.0)
        
        if vm.showContainer {
            StoryContainer()
                .zIndex(1.0)
                .frame(maxHeight: .infinity, alignment: .top)
                .openAppLikeTransition(sacle: frame.height / .screenHeight, offestX: offsetX, offsetY: offsetY)
        }
    }
}

//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var handler = HomeUIActionHandler()
    @StateObject private var storiesViewModel = StoriesViewModel()
    @State private var containerAnimationBeginningFrame: CGRect?
    
    var body: some View {
        ZStack {
            HStack(spacing: 0.0) {
                storyCamView
                
                NavigationView {
                    VStack {
                        StoryIconsView(vm: storiesViewModel) { frame in
                            containerAnimationBeginningFrame = frame
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
        HomeView()
    }
}

// MARK: components
extension HomeView {
    private var storyCamView: some View {
        ZStack {
            if handler.showStoryCamView {
                StoryCamView { image in
                    // TODO:
                } postVideoAction: { url in
                    // TODO:
                } tapCloseAction: {
                    withAnimation(.default) {
                        handler.showStoryCamView.toggle()
                    }
                }
                .frame(width: .screenWidth)
            }
        }
        .ignoresSafeArea()
    }
    
    private var storyContainer: some View {
        GeometryReader { geo in
            if handler.showContainer, let iconFrame = containerAnimationBeginningFrame {
                let offsetX = -(geo.size.width / 2 - iconFrame.midX)
                let offsetY = iconFrame.minY - geo.safeAreaInsets.top
                StoryContainer(vm: storiesViewModel)
                    .zIndex(1.0)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .openAppLikeTransition(sacle: iconFrame.height / .screenHeight, offestX: offsetX, offsetY: offsetY)
            }
        }
    }
}

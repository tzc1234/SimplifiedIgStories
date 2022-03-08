//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    static let coordinateSpaceName = "Home"
    static var topSpacing = 0.0
    
    @StateObject private var vm = StoriesViewModel()
    
    private let titleHeight = 44.0
    private let width = UIScreen.main.bounds.width
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 0.0) {
                storyCamView
                
                ZStack {
                    VStack(alignment: .leading, spacing: 0.0) {
                        Color.clear.frame(height: geo.safeAreaInsets.top)
                        titleView
                        StoryIconsView(stories: vm.stories, onTapAction: vm.tapStoryIcon)
                        Spacer()
                    }
                    
                    storyContainer(geo: geo)
                }
                .coordinateSpace(name: Self.coordinateSpaceName)
                .frame(width: width)
                .environmentObject(vm)
                
            }
            .offset(x: vm.showStoryCamView ? 0.0 : -width)
            .ignoresSafeArea()
            .onAppear {
                Self.topSpacing = geo.safeAreaInsets.top > 20.0 ? geo.safeAreaInsets.top : 0.0
            }
            .onPreferenceChange(IdFramePreferenceKey.self) { idFrameDict in
                vm.storyIconFrames = idFrameDict
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(StoriesViewModel(dataService: MockDataService()))
    }
}

// MARK: components
extension HomeView {
    private var storyCamView: some View {
        ZStack {
            if vm.showStoryCamView {
                StoryCamView(onCloseAction: vm.toggleStoryCamView)
            }
        }
        .frame(width: width)
    }
    
    private var titleView: some View {
        Text("IG Stories")
            .font(.title)
            .bold()
            .frame(height: titleHeight, alignment: .leading)
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder private func storyContainer(geo: GeometryProxy) -> some View {
        if vm.showContainer {
            let currentTopSpacing = geo.safeAreaInsets.top == 0 ? 0 : titleHeight / 2 + geo.safeAreaInsets.top / 2
            let offset = CGSize(
                width: -(geo.size.width / 2 - vm.currentStoryIconFrame.midX + StoryIconsView.spacing / 2),
                height: -(geo.size.height / 2 - vm.currentStoryIconFrame.midY + currentTopSpacing)
            )
            
            StoryContainer()
                .zIndex(1)
                .transition(.iOSNativeOpenAppTransition(offest: offset))
        }
    }
}

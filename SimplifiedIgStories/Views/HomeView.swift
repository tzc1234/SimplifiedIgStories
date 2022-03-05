//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    static let coordinateSpaceName = "Home"
    
    @EnvironmentObject private var modelData: ModelData
    @StateObject private var storyGlobal = StoryGlobalObject()
    
    let titleHeight = 44.0
    let width = UIScreen.main.bounds.width
    
    @State private var showStoryCamView = false
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 0) {
                ZStack {
                    if showStoryCamView {
                        StoryCamView() { toggleStoryCamView() }
                    }
                }
                .frame(width: width)
                
                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear.frame(height: geo.safeAreaInsets.top)
                        titleView
                        
                        StoryIconsView(stories: stories) { index in
                            if stories[index].hasPortion {
                                // go to StoryView
                            } else { // No story portion
                                if stories[index].user.isCurrentUser {
                                    toggleStoryCamView()
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if storyGlobal.showContainer {
                        let topSpacing = geo.safeAreaInsets.top == 0 ? 0 : titleHeight / 2 + geo.safeAreaInsets.top / 2
                        let offset = CGSize(
                            width: -(geo.size.width / 2 - storyGlobal.currentStoryIconFrame.midX + StoryIconsView.spacing / 2),
                            height: -(geo.size.height / 2 - storyGlobal.currentStoryIconFrame.midY + topSpacing)
                        )
                        
                        StoryContainer()
                            .zIndex(1)
                            .transition(.iOSNativeOpenAppTransition(offest: offset))
                    }
                }
                .coordinateSpace(name: Self.coordinateSpaceName)
                .frame(width: width)
                
            }
            .offset(x: showStoryCamView ? 0 : -width)
            .ignoresSafeArea()
            .environmentObject(storyGlobal)
            .onAppear {
                storyGlobal.topSpacing = geo.safeAreaInsets.top > 20.0 ? geo.safeAreaInsets.top : 0.0
            }
            
        }
        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(ModelData())
    }
}

// MARK: computed variables
extension HomeView {
    var stories: [Story] {
        modelData.stories
    }
}

// MARK: components
extension HomeView {
    var titleView: some View {
        Text("IG Stories")
            .font(.title)
            .bold()
            .frame(height: titleHeight, alignment: .leading)
            .padding(.horizontal, 16)
    }
}

// MARK: functions
extension HomeView {
    func toggleStoryCamView() {
        withAnimation(.default) {
            showStoryCamView.toggle()
        }
    }
}

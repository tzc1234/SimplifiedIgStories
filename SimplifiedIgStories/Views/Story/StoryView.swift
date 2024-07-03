//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryView: View {
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    
    let story: Story
    @StateObject var animationHandler: StoryAnimationHandler
    let getStoryPortionView: (Int, Portion) -> StoryPortionView
    let onDisappear: (Int) -> Void
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                ProgressBar(story: story, animationHandler: animationHandler)
                    .frame(height: 2.0, alignment: .center)
                    .padding(.top, 12.0)
                
                HStack {
                    avatarIcon
                    nameText
                    dateText
                    Spacer()
                    closeButton
                }
                .padding(.leading, 20.0)
                
                Spacer()
            }
        }
        .background(storyPortionViews)
        .onAppear {
            print("storyId: \(story.id) view onAppear.")
            animationHandler.startProgressBarAnimation()
        }
        .onDisappear {
            print("storyId: \(story.id) view onDisappear.")
            onDisappear(story.id)
        }
    }
}

extension StoryView {
    private var storyPortionViews: some View {
        ZStack {
            ForEach(Array(zip(story.portions.indices, story.portions)), id: \.1.id) { index, portion in
                if index == animationHandler.currentPortionIndex {
                    getStoryPortionView(index, portion)
                }
            }
        }
        .clipShape(Rectangle())
    }
    
    private var avatarIcon: some View {
        var onTapAction: ((Story) -> Void)?
        if story.user.isCurrentUser {
            onTapAction = { _ in
                homeUIActionHandler.closeStoryContainer(storyId: story.id)
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.3,
                    execute: homeUIActionHandler.showStoryCameraView
                )
            }
        }
        
        return StoryIcon(
            story: story,
            showPlusIcon: story.user.isCurrentUser,
            plusIconBgColor: .white,
            showStroke: false,
            onTapAction: onTapAction
        )
        .frame(width: 40.0, height: 40.0)
    }
    
    private var nameText: some View {
        Text(story.user.title)
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    private var dateText: some View {
        Text(story.lastUpdate?.timeAgoDisplay() ?? "")
            .foregroundColor(.white)
            .font(.subheadline)
    }
    
    private var closeButton: some View {
        Button {
            homeUIActionHandler.closeStoryContainer(storyId: story.id)
        } label: {
            ZStack {
                // Increase close button tap area.
                Color.clear.frame(width: 45.0, height: 45.0)
                Image(systemName: "xmark")
                    .resizable()
                    .foregroundColor(.white)
                    .frame(width: 25.0, height: 25.0)
            }
            .contentShape(Rectangle())
        }
        .padding(.trailing, 10.0)
    }
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView.preview
    }
}

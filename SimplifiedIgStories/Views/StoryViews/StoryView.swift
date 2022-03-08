//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryView: View {
    let story: Story
    @ObservedObject private var storyViewModel: StoryViewModel
    let closeAction: (() -> Void)?
    
    init(story: Story, storyViewModel: StoryViewModel, closeAction: (() -> Void)? = nil) {
        self.story = story
        self.storyViewModel = storyViewModel
        self.closeAction = closeAction
    }
    
    var body: some View {
        ZStack {
            storyPortionViews
            
            DetectableTapGesturePositionView(
                tapCallback: storyViewModel.decidePortionTransitionDirectionBy(point:)
            )
            
            VStack(alignment: .leading) {
                Color.clear.frame(height: HomeView.topSpacing)
                
                ProgressBar(story: story, storyViewModel: storyViewModel)
                    .frame(height: 2.0, alignment: .center)
                    .padding(.top, 8.0)
                
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
        .clipShape(Rectangle())
        .onAppear {
            storyViewModel.initAnimation(story: story)
        }
        
    }
    
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel(dataService: MockDataService())
        let story = storiesViewModel.atLeastOnePortionStories[0]
        StoryView(
            story: story,
            storyViewModel: storiesViewModel.getStoryViewModelBy(story: story)
        )
    }
}

// MARK: components
extension StoryView {
    // TODO: Limit the number of StoryPortionViews.
    private var storyPortionViews: some View {
        ZStack(alignment: .top) {
            ForEach(story.portions) { portion in
                if portion.id == storyViewModel.currentStoryPortionId {
                    StoryPortionView(
                        portionId: portion.id,
                        storyViewModel: storyViewModel,
                        photoName: portion.imageName,
                        videoUrl: portion.videoUrl
                    )
                }
            }
        }
    }
    
    private var avatarIcon: some View {
        Image(story.user.avatar)
            .resizable()
            .scaledToFill()
            .frame(width: 40.0, height: 40.0)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white, lineWidth: 1))
    }
    
    private var nameText: some View {
        Text(story.user.title)
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    private var dateText: some View {
        Text(story.lastUpdateDate?.timeAgoDisplay() ?? "")
            .foregroundColor(.white)
            .font(.subheadline)
    }
    
    private var closeButton: some View {
        Button {
            closeAction?()
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

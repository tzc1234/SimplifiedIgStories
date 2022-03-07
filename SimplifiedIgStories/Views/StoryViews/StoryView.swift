//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

enum StoryPortionTransitionDirection {
    case none, start, forward, backward
}

struct StoryView: View {
    @EnvironmentObject private var vm: StoryViewModel
    
    @State var storyPortionTransitionDirection: StoryPortionTransitionDirection = .none
    @State var currentStoryPortionIndex: Int = 0
    
    let story: Story
    
    var body: some View {
        ZStack {
            storyPortionViews
            
            DetectableTapGesturePositionView { point in
                let screenWidth = UIScreen.main.bounds.width
                if point.x <= screenWidth / 2 {
                    storyPortionTransitionDirection = .backward
                } else {
                    storyPortionTransitionDirection = .forward
                }
            }
            
            VStack(alignment: .leading) {
                Color.clear.frame(height: vm.topSpacing)
                
                ProgressBar(
                    story: story,
                    storyPortionTransitionDirection: $storyPortionTransitionDirection,
                    currentStoryPortionIndex: $currentStoryPortionIndex
                )
                    .frame(height: 2, alignment: .center)
                    .padding(.top, 8)
                
                HStack {
                    avatarIcon
                    nameText
                    dateText
                    Spacer()
                    closeButton
                }.padding(.leading, 20)
                
                Spacer()
            }
        }
        .clipShape(Rectangle())
        .onAppear { initAnimation() }
    }
    
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = StoryViewModel(dataService: MockDataService())
        StoryView(story: vm.stories[1])
            .environmentObject(vm)
    }
}

// MARK: components
extension StoryView {
    // TODO: limit the number of storyPortionViews
    var storyPortionViews: some View {
        ZStack(alignment: .top) {
            ForEach(story.portions.indices) { index in
                if currentStoryPortionIndex == index {
                    StoryPortionView(
                        index: index,
                        photoName: story.portions[index].imageName,
                        videoUrl: story.portions[index].videoUrl
                    )
                }
            }
        }
    }
    
    var avatarIcon: some View {
        Image(story.user.avatar)
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white, lineWidth: 1))
    }
    
    var nameText: some View {
        Text(story.user.title)
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    var dateText: some View {
        Text(story.lastUpdateDate?.timeAgoDisplay() ?? "")
            .foregroundColor(.white)
            .font(.subheadline)
    }
    
    var closeButton: some View {
        Button {
            vm.closeStoryContainer()
        } label: {
            ZStack {
                // Increase close button tap area.
                Color.clear.frame(width: 45, height: 45)
                Image(systemName: "xmark")
                    .resizable()
                    .foregroundColor(.white)
                    .frame(width: 25, height: 25)
            }
            .contentShape(Rectangle())
        }
        .padding(.trailing, 10)
    }
}

// MARK: functions
extension StoryView {
    func initAnimation() {
        if storyPortionTransitionDirection == .none && vm.currentStoryId == story.id {
            print("StoryId: \(story.id) animation start!")
            storyPortionTransitionDirection = .start
        }
    }
}

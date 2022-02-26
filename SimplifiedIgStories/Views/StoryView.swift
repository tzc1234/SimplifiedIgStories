//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryView: View {
    enum AnimationTransitionDirection {
        case none, forward, backward
    }
    
    @State private var transitionDirection: AnimationTransitionDirection = .none
    @State private var currentStoryPortionIndex = 0
    
    @EnvironmentObject private var modelDate: ModelData
    @EnvironmentObject private var globalObject: GlobalObject
    let index: Int
    
    var story: Story {
        modelDate.stories[index]
    }
    
    var body: some View {
        ZStack {
            storyPortionViews
            
            DetectableTapGesturePositionView { point in
                let screenWidth = UIScreen.main.bounds.width
                if point.x <= screenWidth / 2 { // go previous
                    transitionDirection = .backward
                } else { // go next
                    transitionDirection = .forward
                }
            }
            
            VStack(alignment: .leading) {
                Color.clear.frame(height: globalObject.topSpacing)
                
                ProgressBar(transitionDirection: $transitionDirection, currentStoryPortionIndex: $currentStoryPortionIndex)
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
        .onAppear { // init animation
            print("StoryView \(index) appeared!")
            
            globalObject.shouldRotate = true
            if transitionDirection == .none {
                transitionDirection = .forward
            }
        }
        
    }
    
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView(index: 0)
    }
}

// MARK: components
extension StoryView {
    var storyPortionViews: some View {
        ZStack(alignment: .top) {
            ForEach(Array(zip(story.portions.indices, story.portions)), id: \.1.id) { index, portion in
                if currentStoryPortionIndex == index {
                    StoryPortionView(index: index, photoName: portion.imageName)
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
        Text(story.user.name)
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    var dateText: some View {
        Text(story.lastUpdateDate.timeAgoDisplay())
            .foregroundColor(.white)
            .font(.subheadline)
    }
    
    var closeButton: some View {
        Button {
            globalObject.closeStoryContainer()
        } label: {
            ZStack {
                // Increase close button tap area.
                Color.clear.frame(width: 45, height: 45)
                Image(systemName: "xmark")
                    .resizable()
                    .foregroundColor(.white)
                    .frame(width: 25, height: 25)
            }
            .padding(.trailing, 10)
            .contentShape(Rectangle())
        }
    }
}

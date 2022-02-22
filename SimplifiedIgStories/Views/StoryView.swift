//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryView: View {
    @Environment(\.dismiss) var dismiss
    
    enum AnimationTransitionDirection {
        case none, forward, backward
    }
    
    @State private var transitionDirection: AnimationTransitionDirection = .none
    @State private var currentStoryPortionIndex = 0
    
    let story: Story
    
    var body: some View {
        ZStack {
            storyPortionViews

            GeometryReader { geo in
                DetectableTapGesturePositionView { point in
                    if point.x <= geo.size.width / 2 { // go previous
                        transitionDirection = .backward
                    } else { // go next
                        transitionDirection = .forward
                    }
                }
                .ignoresSafeArea()
            }
            
            VStack(alignment: .leading) {
                ProgressBar(numOfSegments: story.portions.count, transitionDirection: $transitionDirection, currentStoryPortionIndex: $currentStoryPortionIndex)
                    .frame(height: 2, alignment: .center)
                    .padding(.top, 8)
                    .statusBar(hidden: true)

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
        .navigationBarHidden(true)
        .onAppear { // init animation
            if transitionDirection == .none {
                transitionDirection = .forward
            }
        }
    }
    
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView(story: ModelData().stories[0])
    }
}

// MARK: components
extension StoryView {
    var storyPortionViews: some View {
        ZStack {
            ForEach(story.portions.indices) { index in
                let portion = story.portions[index]
                StoryPortionView(index: index, photoName: portion.imageName)
                    .opacity(currentStoryPortionIndex == index ? 1.0 : 0.0)
            }
        }
    }
    
    var avatarIcon: some View {
        Image(story.user.avatar)
            .resizable()
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
            dismiss()
        } label: {
            ZStack {
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

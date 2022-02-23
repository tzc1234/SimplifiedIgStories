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
    
    var story: Story {
        modelDate.stories[globalObject.currentStoryIconIndex]
    }
    
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
            }
            
            VStack(alignment: .leading) {
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
        .statusBar(hidden: true)
        .onAppear { // init animation
            if transitionDirection == .none {
                transitionDirection = .forward
            }
        }
    }
    
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView()
    }
}

// MARK: components
extension StoryView {
    var storyPortionViews: some View {
        ZStack(alignment: .top) {
            ForEach(Array(zip(story.portions.indices, story.portions)), id: \.1.id) { index, portion in
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
            // Don't use .spring(). If you switch the StoryContainer fast from one, close then open another,
            // there will be a weird behaviour. The StoryView can not be updated completely and broken.
            withAnimation(.easeInOut) {
                globalObject.showContainer.toggle()
            }
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

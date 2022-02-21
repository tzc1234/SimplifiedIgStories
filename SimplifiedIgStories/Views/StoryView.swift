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
    @State private var currentStoryDisplayIndex = 0
    @State private var storyDisplays: [StoryDisplayView] = [
        StoryDisplayView(photoName: "sea1"),
        StoryDisplayView(photoName: "sea2"),
        StoryDisplayView(photoName: "sea3")
    ]
    
    var body: some View {
        ZStack {
            storyDisplayViews

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
                ProgressBar(numOfSegments: storyDisplays.count, transitionDirection: $transitionDirection, currentStoryDisplayIndex: $currentStoryDisplayIndex)
                    .frame(height: 2, alignment: .center)
                    .padding(.top, 8)
                    .statusBar(hidden: true)

                HStack {
                    avatarIcon
                    nameText
                    dateText
                    Spacer()
                    closeButton
                }.padding(.horizontal, 20)

                Spacer()
            }
        }
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
    var storyDisplayViews: some View {
        ZStack {
            ForEach(storyDisplays.indices) { index in
                storyDisplays[index]
                    .onSetIndex(index)
                    .opacity(currentStoryDisplayIndex == index ? 1.0 : 0.0)
            }
        }
    }
    
    var avatarIcon: some View {
        Image("avatar")
            .resizable()
            .frame(width: 40, height: 40)
            .overlay(Circle().strokeBorder(.white, lineWidth: 1))
    }
    
    var nameText: some View {
        Text("Person0")
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    var dateText: some View {
        Text("15h")
            .foregroundColor(.white)
            .font(.subheadline)
    }
    
    var closeButton: some View {
        Button {
            print("Close tapped.")
        } label: {
            Image(systemName: "xmark")
                .resizable()
                .foregroundColor(.white)
                .frame(width: 25, height: 25)
        }
    }
}

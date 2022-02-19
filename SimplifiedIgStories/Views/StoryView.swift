//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

// TODO: any better name for this observable object?
final class TracingSegmentAnimation: ObservableObject {
    @Published var currentSegmentIndex: Int = -1
    var transitionDirection: AnimationTransitionDirection = .forward
    
    enum AnimationTransitionDirection {
        case forward, backward
    }
}

struct StoryView: View {
    @ObservedObject var tracingSegmentAnimation = TracingSegmentAnimation()
    
    @State var storyDisplays: [StoryDisplayView] = [
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
                        tracingSegmentAnimation.transitionDirection = .backward
                        tracingSegmentAnimation.currentSegmentIndex -= 1
                    } else { // go next
                        tracingSegmentAnimation.transitionDirection = .forward
                        tracingSegmentAnimation.currentSegmentIndex += 1
                    }
                }
                .ignoresSafeArea()
            }
            
            VStack(alignment: .leading) {
                ProgressBar(tracingSegmentAnimation: tracingSegmentAnimation, numOfSegments: storyDisplays.count)
                    .frame(height: 3, alignment: .center)

                HStack {
                    avatarIcon
                    nameText
                    dateText
                    Spacer()
                    closeButton
                }.padding(.horizontal, 18)

                Spacer()
            }
        }
        .onAppear { // start animation
            if tracingSegmentAnimation.currentSegmentIndex == -1 {
                tracingSegmentAnimation.transitionDirection = .forward
                tracingSegmentAnimation.currentSegmentIndex = 0
            }
        }
        
    }
    
    func storyDisplayOpacity(index: Int) -> Double {
        let currentIndex: Int
        if tracingSegmentAnimation.currentSegmentIndex < 0 {
            currentIndex = 0
        } else if tracingSegmentAnimation.currentSegmentIndex > storyDisplays.count - 1 {
            currentIndex = storyDisplays.count - 1
        } else {
            currentIndex = tracingSegmentAnimation.currentSegmentIndex
        }
        
        return currentIndex == index ? 1.0 : 0.0
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
                    .opacity(storyDisplayOpacity(index: index))
            }
        }
    }
    
    var avatarIcon: some View {
        Image("avatar")
            .resizable()
            .frame(width: 45, height: 45)
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
                .frame(width: 35, height: 35)
        }
    }
}

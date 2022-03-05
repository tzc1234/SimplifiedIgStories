//
//  StoryContainer.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryContainer: View {
    @EnvironmentObject private var modelData: ModelData
    @EnvironmentObject private var storyGlobal: StoryGlobalObject
    
    @GestureState private var translation: CGFloat = 0
    
    private let width = UIScreen.main.bounds.width
    private let height = UIScreen.main.bounds.height
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // TODO: A risk of memory leak if too many stories.
            ForEach(stories.indices) { index in
                if stories[index].portions.count > 0 {
                    GeometryReader { geo in
                        let frame = geo.frame(in: .global)
                        StoryView(storyIndex: index)
                        // Cubic transition reference: https://www.youtube.com/watch?v=NTun83toSQQ&ab_channel=Kavsoft
                            .rotation3DEffect(
                                storyGlobal.shouldAnimateCubicRotation ? .degrees(getRotationDegree(offsetX: frame.minX)) : .degrees(0),
                                axis: (x: 0.0, y: 1.0, z: 0.0),
                                anchor: frame.minX > 0 ? .leading : .trailing,
                                anchorZ: 0.0,
                                perspective: 2.5
                            )
                    }
                    .frame(width: width, height: height)
                    .ignoresSafeArea()
                    .opacity(index != currentStoryIndex && !storyGlobal.shouldAnimateCubicRotation ? 0.0 : 1.0)
                }
                
            }
        }
        .frame(width: width, alignment: .leading)
        .offset(x: -CGFloat(currentStoryIndex - firstStoryIndex) * width)
        .offset(x: translation)
        .animation(.interactiveSpring(), value: currentStoryIndex)
        .animation(.interactiveSpring(), value: translation)
        .gesture(
            DragGesture()
                .updating($translation) { value, state, transaction in
                    storyGlobal.isDragging = true
                    storyGlobal.storyIndexBeforeDragged = currentStoryIndex
                    state = value.translation.width
                }
                .onEnded { value in
                    let offset = value.translation.width / width
                    
                    // Imitate the close behaviour of IG story when dragging right in the first story,
                    // or dragging left in the last story.
                    if (currentStoryIndex == firstStoryIndex && offset > 0.2) ||
                        (currentStoryIndex == storyCount - 1 && offset < -0.2) {
                        storyGlobal.closeStoryContainer()
                    } else {
                        let nextIndex = Int((CGFloat(currentStoryIndex) - offset).rounded())
                        storyGlobal.currentStoryIndex = min(nextIndex, storyCount - 1)
                    }
                    
                    storyGlobal.isDragging = false
                }
        )
        .statusBar(hidden: true)
        
    }
    
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        StoryContainer()
    }
}

// MARK: computed variables
extension StoryContainer {
    private var stories: [Story] {
        modelData.stories
    }
    
    private var storyCount: Int {
        stories.count
    }
    
    private var currentStoryIndex: Int {
        storyGlobal.currentStoryIndex
    }
    
    private var firstStoryIndex: Int {
        modelData.firstStoryIndex
    }
}

// MARK: functions
extension StoryContainer {
    private func getRotationDegree(offsetX: CGFloat) -> Double {
        let tempAngle = offsetX / (width / 2)
        let rotationDegree = 20.0
        return tempAngle * rotationDegree
    }
}

//
//  StoryContainer.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryContainer: View {
    @EnvironmentObject private var modelDate: ModelData
    @EnvironmentObject private var storyGlobal: StoryGlobalObject
    
    @GestureState private var translation: CGFloat = 0
    
    private let width = UIScreen.main.bounds.width
    private let height = UIScreen.main.bounds.height
    
    private var storyCount: Int {
        modelDate.stories.count
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(modelDate.stories.indices) { index in
                GeometryReader { geo in
                    let frame = geo.frame(in: .global)
                    StoryView(storyIndex: index)
                        // Cubic transition reference: https://www.youtube.com/watch?v=NTun83toSQQ&ab_channel=Kavsoft
                        .rotation3DEffect(
                            storyGlobal.shouldRotate ? .degrees(getRotationDegree(offsetX: frame.minX)) : .degrees(0),
                            axis: (x: 0.0, y: 1.0, z: 0.0),
                            anchor: frame.minX > 0 ? .leading : .trailing,
                            perspective: 2.5
                        )
                }
                .frame(width: width, height: height)
                .ignoresSafeArea()
            }
            
        }
        .frame(width: width, alignment: .leading)
        .offset(x: -CGFloat(storyGlobal.currentStoryIndex) * width)
        .offset(x: translation)
        .animation(.interactiveSpring(), value: storyGlobal.currentStoryIndex)
        .animation(.interactiveSpring(), value: translation)
        .gesture(
            DragGesture()
                .updating($translation) { value, state, transaction in
                    state = value.translation.width
                }
                .onEnded { value in
                    let offset = value.translation.width / width
                    
                    // Imitate the close behaviour of IG story when dragging right in the first story,
                    // or dragging left in the last story.
                    if storyGlobal.currentStoryIndex == 0 && offset > 0.2 {
                        storyGlobal.closeStoryContainer()
                    } else if storyGlobal.currentStoryIndex == storyCount - 1 && offset < -0.2 {
                        storyGlobal.closeStoryContainer()
                    } else {
                        let nextIndex = Int((CGFloat(storyGlobal.currentStoryIndex) - offset).rounded())
                        storyGlobal.currentStoryIndex = min(nextIndex, storyCount - 1)
                    }
                }
        )
        .statusBar(hidden: true)
        
    }
    
    func getRotationDegree(offsetX: CGFloat) -> Double {
        let tempAngle = offsetX / (width / 2)
        let rotationDegree = 20.0
        return tempAngle * rotationDegree
    }
    
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        StoryContainer()
    }
}

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

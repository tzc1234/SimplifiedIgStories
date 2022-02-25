//
//  StoryContainer.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryContainer: View {
    @EnvironmentObject private var modelDate: ModelData
    @EnvironmentObject private var globalObject: GlobalObject
    
    var body: some View {
        // Reference: https://www.youtube.com/watch?v=NTun83toSQQ&ab_channel=Kavsoft
        TabView(selection: $globalObject.currentStoryIconIndex) {
            ForEach(modelDate.stories.indices) { index in
                GeometryReader { geo in
                    let frame = geo.frame(in: .global)
                    StoryView(index: index)
                        .tag(index)
                        .rotation3DEffect(
                            globalObject.shouldRotate ? .degrees(getRotationDegree(offsetX: frame.minX)) : .degrees(0),
                            axis: (x: 0.0, y: 1.0, z: 0.0),
                            anchor: frame.minX > 0 ? .leading : .trailing,
                            perspective: 2.5
                        )
                        .ignoresSafeArea()
                        .preference(key: FramePreferenceKey.self, value: frame)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .statusBar(hidden: true)
        
    }
    
    func getRotationDegree(offsetX: CGFloat) -> Double {
        let width = UIScreen.main.bounds.width
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

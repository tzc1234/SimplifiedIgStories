//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

final class TracingSegmentAnimation: ObservableObject {
    @Published var currentSegmentIndex: Int = -1
    @Published var isSegmentAnimationFinishedDict: [Int: Bool] = [:]
    @Published var shouldAnimationPause: Bool = false
}

struct ProgressBar: View {
    @ObservedObject var tracingSegmentAnimation = TracingSegmentAnimation()
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(0..<10) { index in
                ProgressBarSegment(index: index, tracingSegmentAnimation: tracingSegmentAnimation)
                
                Spacer(minLength: 2)
            }
        }
        .frame(height: 10)
        .padding(.horizontal, 10)
        .onTapGesture {
            if tracingSegmentAnimation.currentSegmentIndex == -1 {
                tracingSegmentAnimation.currentSegmentIndex = 0
            } else {
                tracingSegmentAnimation.shouldAnimationPause.toggle()
            }
        }
        .onChange(of: tracingSegmentAnimation.isSegmentAnimationFinishedDict[tracingSegmentAnimation.currentSegmentIndex], perform: { newValue in
            if newValue == true {
                tracingSegmentAnimation.currentSegmentIndex += 1
            }
        })
            
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar()
    }
}

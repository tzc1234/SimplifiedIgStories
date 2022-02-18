//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

// TODO: any better name for this observable object?
final class TracingSegmentAnimation: ObservableObject {
    @Published var currentSegmentIndex: Int = -1
    @Published var isSegmentAnimationFinishedDict: [Int: Bool] = [:]
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
        .padding(.horizontal, 10)
        .onTapGesture {
            // start animation
            if tracingSegmentAnimation.currentSegmentIndex == -1 {
                tracingSegmentAnimation.currentSegmentIndex = 0
            }
        }
        // for trigger next bar segment animation
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

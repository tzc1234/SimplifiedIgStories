//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

struct ProgressBar: View {
    var tracingSegmentAnimation: TracingSegmentAnimation
    let numOfSegments: Int
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(0..<numOfSegments) { index in
                ProgressBarSegment(index: index, tracingSegmentAnimation: tracingSegmentAnimation)
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar(tracingSegmentAnimation: TracingSegmentAnimation(), numOfSegments: 10)
    }
}

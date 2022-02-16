//
//  ProgressBarSegment.swift
//  IgStoriesSwiftUI
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct TraceableRectangle: Shape {
    let startX: Double
    var endX: Double
    let tracingEndX: TracingEndX
    
    var animatableData: Double {
        get { endX }
        set {
            endX = newValue
            tracingEndX.updateCurrentEndX(newValue)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: startX, y: rect.minY))
        path.addLine(to: CGPoint(x: endX, y: rect.minY))
        path.addLine(to: CGPoint(x: endX, y: rect.maxY))
        path.addLine(to: CGPoint(x: startX, y: rect.maxY))
        
        return path
    }
}

final class TracingEndX: ObservableObject {
    @Published var currentEndX: Double
    
    init(currentEndX: Double) {
        self.currentEndX = currentEndX
    }
    
    func updateCurrentEndX(_ endX: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.currentEndX = endX
        }
    }
}

struct ProgressBarSegment: View {
    @State private var endX = 0.0
    @ObservedObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    @State private var isAnimating = false
    
    let duration = 1.0
    
    let index: Int
    @ObservedObject private var tracingSegmentAnimation: TracingSegmentAnimation
    
    init(index: Int, tracingSegmentAnimation: TracingSegmentAnimation) {
        self.index = index
        self.tracingSegmentAnimation = tracingSegmentAnimation
    }
    
    var body: some View {
        GeometryReader { geo in
            TraceableRectangle(startX: 0, endX: endX, tracingEndX: tracingEndX)
                .fill(.white)
                .background(Color(.lightGray).opacity(0.5))
                .cornerRadius(6)
                .onChange(of: tracingEndX.currentEndX) { currentEndX in
                    if currentEndX == geo.size.width {
                        tracingEndX.updateCurrentEndX(0.0)
                        isAnimating = false
                        tracingSegmentAnimation.isSegmentAnimationFinishedDict[index] = true
                    }
                }
                .onChange(of: tracingSegmentAnimation.currentSegmentIndex) { currentSegmentIndex in
                    if currentSegmentIndex == index {
                        startOrPauseAnimation(geo: geo)
                    }
                }.onChange(of: tracingSegmentAnimation.shouldAnimationPause) { _ in
                    if tracingSegmentAnimation.currentSegmentIndex == index {
                        startOrPauseAnimation(geo: geo)
                    }
                }
        }
    }
    
    func startOrPauseAnimation(geo: GeometryProxy) {
        if endX == geo.size.width { endX = 0 }
        isAnimating.toggle()
        
        let duration = isAnimating ? duration * (1 - tracingEndX.currentEndX / geo.size.width) : 0
        
        withAnimation(.linear(duration: duration)) {
            endX = isAnimating ? geo.size.width : tracingEndX.currentEndX
        }
    }
    
}

struct ProgressBarSegment_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarSegment(
            index: 0,
            tracingSegmentAnimation: TracingSegmentAnimation()
        )
        .preferredColorScheme(.dark)
        .frame(width: 300, height: 30)
    }
}

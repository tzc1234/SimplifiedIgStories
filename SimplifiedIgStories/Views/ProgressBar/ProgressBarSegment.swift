//
//  ProgressBarSegment.swift
//  SimplifiedIgStories
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
    @Environment(\.scenePhase) var scenePhase
    @State private var isInital = true
    
    @State private var endX = 0.0
    // ProgressBarSegment will frequently be recreate,
    // TracingEndX must be a @StateObject to keep it unchange.
    @StateObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    
    let duration = 6.0
    
    enum AnimationStatus {
        case pending, playing, pausing, finished
    }
    @State var animationStatus: AnimationStatus = .pending
    
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
                    // Finish
                    if currentEndX >= geo.size.width {
                        animationStatus = .finished
                    }
                }
                .onChange(of: tracingSegmentAnimation.currentSegmentIndex) { newValue in
                    let currentSegmentIndex = newValue < 0 ? 0 : newValue
                    if currentSegmentIndex == index { // Play animation
//                        isInital = false
                        animationStatus = .playing
                    } else {
                        if index < currentSegmentIndex { // For Previous segments:
                            animationStatus = .finished
                        } else { // For following segents:
                            animationStatus = .pending
                        }
                    }
                }
                .onChange(of: animationStatus) { animationStatus in
                    let duration: Double
                    if animationStatus == .playing {
                        if tracingSegmentAnimation.transitionDirection == .backward {
                            endX = 0
                            duration = self.duration
                        } else {
                            duration = self.duration * (1 - tracingEndX.currentEndX / geo.size.width)
                        }
                        
                        tracingSegmentAnimation.transitionDirection = .forward
                    } else {
                        duration = 0
                    }
                    
                    withAnimation(.linear(duration: duration)) {
                        switch animationStatus {
                        case .pending:
                            endX = 0
                        case .playing:
                            endX = geo.size.width
                        case .pausing:
                            endX = tracingEndX.currentEndX
                        case .finished:
                            endX = geo.size.width + 0.1 // trick to stop animation!
                            tracingEndX.updateCurrentEndX(0)

                            if index == tracingSegmentAnimation.currentSegmentIndex {
                                tracingSegmentAnimation.currentSegmentIndex = index + 1
                            }
                        }
                    }
                }
                // Pause animation when scenePhase inactive
//                .onChange(of: scenePhase) { newPhase in
//                    if !isInital {
//                        if newPhase == .active {
//                            animationStatus = .playing
//                        } else if newPhase == .inactive {
//                            animationStatus = .pausing
//                        }
//                    }
//                }
            
        }
    }
    
}

struct ProgressBarSegment_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarSegment(
            index: 0,
            tracingSegmentAnimation: TracingSegmentAnimation()
        )
        .frame(width: 300, height: 30)
    }
}

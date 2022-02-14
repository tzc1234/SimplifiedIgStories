//
//  StoryIcon.swift
//  IgStoriesSwiftUI
//
//  Created by Tsz-Lung on 13/2/2022.
//

import SwiftUI

struct Arc: Shape {
    let startAngle: Double
    var endAngle: Double
    let clockwise: Bool
    let traceEndAngle: TraceEndAngle
    
    var animatableData: Double {
        get { endAngle }
        set {
            traceEndAngle.updateEndAngle(newValue)
            endAngle = newValue
        }
    }
    
    init(startAngle: Double, endAngle: Double, clockwise: Bool, traceEndAngle: TraceEndAngle) {
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.clockwise = clockwise
        self.traceEndAngle = traceEndAngle
    }
    
    func path(in rect: CGRect) -> Path {
        let rotationAdjustment: Angle = .degrees(90)
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(startAngle) - rotationAdjustment,
            endAngle: .degrees(endAngle) - rotationAdjustment,
            clockwise: !clockwise
        )
        return path
    }
}

final class TraceEndAngle: ObservableObject {
    @Published private(set) var currentEndAngle: Double
    
    init(currentEndAngle: Double) {
        self.currentEndAngle = currentEndAngle
    }
    
    func updateEndAngle(_ endAngle: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.currentEndAngle = endAngle
        }
    }
}

struct StoryIcon: View {
    @State var endAngle: Double
    @ObservedObject var traceEndAngle: TraceEndAngle
    @State var isAnimationPaused = true
    @State var animationDuration = 8.0
    
    let animatedStrokeWidth = 10.0
    
    init(endAngle: Double) {
        self.endAngle = endAngle
        self.traceEndAngle = TraceEndAngle(currentEndAngle: endAngle)
    }
    
    var body: some View {
        ZStack {
            Arc(startAngle: 0, endAngle: endAngle, clockwise: true, traceEndAngle: traceEndAngle)
                .stroke(
                    .linearGradient(
                        colors: [.orange, .red],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    lineWidth: animatedStrokeWidth
                )
                .padding(animatedStrokeWidth)
                
            Image("avatar")
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: 6))
                .padding(animatedStrokeWidth)
        }
        .onTapGesture {
            isAnimationPaused.toggle()
            withAnimation(isAnimationPaused ? .linear(duration: 0) : .linear(duration: animationDuration)) {
                if isAnimationPaused {
                    let currentEndAngle = traceEndAngle.currentEndAngle
                    print("currentEndAngle: \(currentEndAngle)")
                    endAngle = currentEndAngle
                } else {
                    endAngle = 360.0
                }
            }
        }
    }
}

struct StoryIcon_Previews: PreviewProvider {
    static var previews: some View {
        StoryIcon(endAngle: .zero)
    }
}

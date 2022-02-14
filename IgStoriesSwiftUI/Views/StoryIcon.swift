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
    let traceEndAngle: TracingEndAngle
    
    var animatableData: Double {
        get { endAngle }
        set {
            traceEndAngle.updateEndAngle(newValue)
            endAngle = newValue
        }
    }
    
    init(startAngle: Double, endAngle: Double, clockwise: Bool, traceEndAngle: TracingEndAngle) {
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

final class TracingEndAngle: ObservableObject {
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
    @State var endAngle: Double = 0.0
    @ObservedObject var tracingEndAngle = TracingEndAngle(currentEndAngle: 0.0)
    
    let animationDuration: Double = 1.0
    @State private var currentAnimationDuration: Double = 0.0
    
    enum AnimationStatus {
        case pending, play, pause
    }
    @State private(set) var animationStatus: AnimationStatus = .pending {
        didSet {
            switch animationStatus {
            case .pending, .pause:
                currentAnimationDuration = 0.0
            case .play:
                if endAngle == 360.0 { endAngle = 0.0 }
                if oldValue == .pending {
                    currentAnimationDuration = animationDuration
                } else {
                    currentAnimationDuration = animationDuration * (1 - tracingEndAngle.currentEndAngle / 360.0)
                }
            }
        }
    }
    
    let animatedStrokeWidth = 10.0
    
    var body: some View {
        ZStack {
            Arc(startAngle: 0, endAngle: endAngle, clockwise: true, traceEndAngle: tracingEndAngle)
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
            
            Image("add")
                .resizable()
                .scaledToFit()
                .background(Circle().fill(.white).scaleEffect(1.1))
                .aspectRatio(0.3, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.bottom, 20)
                .padding(.trailing, 10)
        }
        .scaledToFit()
        .onTapGesture {
            changeAnimationStatus()
            withAnimation(.linear(duration: currentAnimationDuration)) {
                switch animationStatus {
                case .pending:
                    break
                case .play:
                    endAngle = 360.0
                case .pause:
                    endAngle = tracingEndAngle.currentEndAngle
                }
            }
        }.onAnimationCompleted(for: endAngle) {
            if endAngle == 360.0 { animationStatus = .pending }
        }
    }
    
    func changeAnimationStatus() {
        switch animationStatus {
        case .pending:
            animationStatus = .play
        case .play:
            animationStatus = .pause
        case .pause:
            animationStatus = .play
        }
    }
    
}

struct StoryIcon_Previews: PreviewProvider {
    static var previews: some View {
        StoryIcon()
    }
}

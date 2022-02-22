//
//  StoryIcon.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/2/2022.
//

import SwiftUI

struct TraceableArc: InsettableShape {
    let startAngle: Double
    var endAngle: Double
    let clockwise: Bool
    let traceEndAngle: TracingEndAngle
    var insetAmount = 0.0
    
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
            radius: rect.width / 2 - insetAmount,
            startAngle: .degrees(startAngle) - rotationAdjustment,
            endAngle: .degrees(endAngle) - rotationAdjustment,
            clockwise: !clockwise
        )
        return path
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount = amount
        return arc
    }
}

final class TracingEndAngle: ObservableObject {
    @Published var currentEndAngle: Double
    
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
    @Environment(\.scenePhase) var scenePhase
    
    @State var endAngle = 360.0
    @ObservedObject private var tracingEndAngle = TracingEndAngle(currentEndAngle: 0.0)
    
    let animationDuration = 1.0
    @State private var currentAnimationDuration = 0.0
    @State private(set) var isAnimating = false
    
    @State private var isAnimationPaused = false
    
    var title: String?
    var avatar: String
    var isPlusIconShown: Bool
    
    init(avatar: String, title: String? = nil, isShownAddIcon: Bool = false) {
        self.avatar = avatar
        self.title = title
        self.isPlusIconShown = isShownAddIcon
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            ZStack {
                TraceableArc(startAngle: 0, endAngle: endAngle, clockwise: true, traceEndAngle: tracingEndAngle)
                    .strokeBorder(
                        .linearGradient(
                            colors: [.red, .orange],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        lineWidth: 10.0, antialiased: true
                    )
                
                GeometryReader { geo in
                    Image(avatar)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: geo.size.width, height: geo.size.width, alignment: .center)
                        .scaleEffect(0.9)
                        .background(Circle().fill(.background).scaleEffect(0.95))
                }
                
                if isPlusIconShown {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .background(Circle().fill(.background).scaleEffect(1.1))
                        .aspectRatio(0.3, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding([.bottom, .trailing], 4)
                }
            }
            .scaledToFit()
//            .onTapGesture {
//                startStrokeAnimation()
//            }
            .onChange(of: tracingEndAngle.currentEndAngle) { newValue in
                if newValue == 360.0 {
                    resetStrokeAnimationAfterCompletion()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active && isAnimationPaused {
                    startStrokeAnimation()
                    isAnimationPaused = false
                } else if newPhase == .inactive && !isAnimationPaused {
                    pauseStrokeAnimation()
                    isAnimationPaused = true
                }
            }
            
            if let title = title {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
        }
    }
    
}

struct StoryIcon_Previews: PreviewProvider {
    static var previews: some View {
        StoryIcon(avatar: "avatar")
    }
}

// MARK: functions
extension StoryIcon {
    func startStrokeAnimation() {
        if !isAnimating {
            isAnimating.toggle()
            
            // reset endAngle to 0 if the animation is finished
            if endAngle == 360 { endAngle = 0 }
            
            let animationDuration = animationDuration * (1 - tracingEndAngle.currentEndAngle / 360.0)
            withAnimation(.easeInOut(duration: animationDuration)) {
                endAngle = 360
            }
        }
    }
    
    func pauseStrokeAnimation() {
        if isAnimating {
            isAnimating.toggle()
            withAnimation(.easeInOut(duration: 0)) {
                endAngle = tracingEndAngle.currentEndAngle
            }
        }
    }
    
    func resetStrokeAnimationAfterCompletion() {
        // reset currentEndAngle to 0 after finishing animation
        tracingEndAngle.currentEndAngle = 0
        isAnimating = false
    }
}

//
//  StoryIcon.swift
//  IgStoriesSwiftUI
//
//  Created by Tsz-Lung on 13/2/2022.
//

import SwiftUI

struct Arc: InsettableShape {
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
    @State var endAngle = 0.0
    @ObservedObject var tracingEndAngle = TracingEndAngle(currentEndAngle: 0.0)
    
    let animationDuration = 1.0
    @State private var currentAnimationDuration = 0.0
    
    enum AnimationStatus {
        case pending, play, pause, end
    }
    @State private var animationStatus: AnimationStatus {
        didSet {
            switch animationStatus {
            case .pending:
                currentAnimationDuration = 0
                endAngle = 0
            case .play:
                if oldValue == .pending {
                    currentAnimationDuration = animationDuration
                } else {
                    currentAnimationDuration = animationDuration * (1 - tracingEndAngle.currentEndAngle / 360.0)
                }
                endAngle = 360
            case .pause:
                currentAnimationDuration = 0
                endAngle = tracingEndAngle.currentEndAngle
            case .end:
                currentAnimationDuration = 0
                endAngle = 360
            }
        }
    }
    
    var title: String? = "Title"
    
    init() {
        animationStatus = .pending
    }
    
    var body: some View {
        VStack {
            ZStack {
                Arc(startAngle: 0, endAngle: endAngle, clockwise: true, traceEndAngle: tracingEndAngle)
                    .strokeBorder(
                        .linearGradient(
                            colors: [.orange, .red],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        lineWidth: 10.0
                    )
                    .animation(.linear(duration: currentAnimationDuration), value: animationStatus)
                
                Image("avatar")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.9)
                    .clipShape(Circle())
                    .background(Circle().fill(.background).scaleEffect(0.95))
                
                Image("add")
                    .resizable()
                    .scaledToFit()
                    .background(Circle().fill(.background).scaleEffect(1.1))
                    .aspectRatio(0.3, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.bottom)
                    .padding(.trailing, 10)
            }
            .scaledToFit()
            .padding(EdgeInsets(top: -5, leading: -5, bottom: -5, trailing: -5))
            .onTapGesture {
                Task { await changeAnimationStatus() }
            }.onChange(of: tracingEndAngle.currentEndAngle) { newValue in
                if newValue == 360 {
                    animationStatus = .end
                }
            }
            
            if let title = title {
                Text(title).font(.headline)
            }

        }
    }
    
    func changeAnimationStatus() async {
        switch animationStatus {
        case .pending:
            animationStatus = .play
        case .play:
            if tracingEndAngle.currentEndAngle == 360 {
                animationStatus = .end
            } else {
                animationStatus = .pause
            }
        case .pause:
            animationStatus = .play
        case .end:
            animationStatus = .pending
            // give a moment let Arc reset
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            animationStatus = .play
        }
    }
    
}

struct StoryIcon_Previews: PreviewProvider {
    static var previews: some View {
        StoryIcon()
    }
}

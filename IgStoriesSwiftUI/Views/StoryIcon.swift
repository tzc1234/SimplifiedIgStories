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
    @State var endAngle = 360.0
    @ObservedObject var tracingEndAngle = TracingEndAngle(currentEndAngle: 0.0)
    
    let animationDuration = 1.0
    @State private var currentAnimationDuration = 0.0
    @State var isAnimating = false
    
    var title: String?
    var isShownAddIcon: Bool
    
    init(title: String? = nil, isShownAddIcon: Bool = false) {
        self.title = title
        self.isShownAddIcon = isShownAddIcon
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            ZStack {
                Arc(startAngle: 0, endAngle: endAngle, clockwise: true, traceEndAngle: tracingEndAngle)
                    .strokeBorder(
                        .linearGradient(
                            colors: [.orange, .red],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        lineWidth: 10.0, antialiased: true
                    )
                
                Image("avatar")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.85)
                    .clipShape(Circle())
                    .background(Circle().fill(.background).scaleEffect(0.9))
                
                if isShownAddIcon {
                    Image("add")
                        .resizable()
                        .scaledToFit()
                        .background(Circle().fill(.background).scaleEffect(1.1))
                        .aspectRatio(0.3, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding([.bottom, .trailing], 4)
                }
            }
            .scaledToFit()
            .onTapGesture {
                // reset endAngle to 0 after finishing animation
                if endAngle == 360 { endAngle = 0 }
                
                isAnimating.toggle()

                let animationDuration = isAnimating ? animationDuration * (1 - tracingEndAngle.currentEndAngle / 360.0) : 0
                withAnimation(.linear(duration: animationDuration)) {
                    endAngle = isAnimating ? 360 : tracingEndAngle.currentEndAngle
                }
            }.onChange(of: tracingEndAngle.currentEndAngle) { newValue in
                if newValue == 360.0 {
                    // reset currentEndAngle to 0 after finishing animation
                    tracingEndAngle.currentEndAngle = 0
                    isAnimating = false
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
        StoryIcon()
    }
}

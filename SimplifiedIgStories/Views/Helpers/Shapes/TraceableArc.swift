//
//  TraceableArc.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct TraceableArc: InsettableShape {
    let startAngle: Double
    private(set) var endAngle: Double
    let clockwise: Bool
    let traceEndAngle: TracingEndAngle
    private(set) var insetAmount = 0.0
    
    var animatableData: Double {
        get { endAngle }
        set {
            Task { @MainActor [weak traceEndAngle] in
                traceEndAngle?.currentEndAngle = newValue
            }
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
            radius: rect.width/2 - insetAmount,
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

@MainActor
final class TracingEndAngle: ObservableObject {
    @Published var currentEndAngle: Double
    
    init(currentEndAngle: Double) {
        self.currentEndAngle = currentEndAngle
    }
}

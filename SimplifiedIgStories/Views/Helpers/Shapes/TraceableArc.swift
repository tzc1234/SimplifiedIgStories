//
//  TraceableArc.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

// MARK: - TraceableArc
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

// MARK: - TracingEndAngle
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

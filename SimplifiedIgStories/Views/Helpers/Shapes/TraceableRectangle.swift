//
//  TraceableRectangle.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 25/2/2022.
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
            Task { @MainActor [weak tracingEndX] in
                tracingEndX?.updateCurrentEndX(newValue)
            }
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: startX, y: rect.minY))
        path.addLine(to: CGPoint(x: endX, y: rect.minY))
        path.addLine(to: CGPoint(x: endX, y: rect.maxY))
        path.addLine(to: CGPoint(x: startX, y: rect.maxY))
        path.addLine(to: CGPoint(x: startX, y: rect.minY))
        
        return path
    }
}

@MainActor
final class TracingEndX: ObservableObject {
    @Published private(set) var currentEndX: Double
    
    init(currentEndX: Double) {
        self.currentEndX = currentEndX
    }
    
    func updateCurrentEndX(_ endX: Double) {
        self.currentEndX = endX
    }
}

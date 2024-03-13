//
//  TraceableRectangle.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 25/2/2022.
//

import SwiftUI

struct TraceableRectangle: Shape {
    let startX: Double
    private(set) var endX: Double
    let tracingEndX: TracingEndX
    
    var animatableData: Double {
        get { endX }
        set {
            endX = newValue
            Task { @MainActor [weak tracingEndX] in
                tracingEndX?.currentEndX = newValue
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
    @Published var currentEndX: Double
    
    init(currentEndX: Double) {
        self.currentEndX = currentEndX
    }
}

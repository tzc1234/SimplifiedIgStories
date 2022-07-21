//
//  TraceableRectangle.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 25/2/2022.
//

import SwiftUI

// MARK: - TraceableRectangle
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
        path.addLine(to: CGPoint(x: startX, y: rect.minY))
        
        return path
    }
}

// MARK: - TracingEndX
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

//
//  VideoRecordButton.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 3/3/2022.
//

import SwiftUI

struct VideoRecordButton: View {
    @GestureState private var isLongPressing = false
    @State private var isTapped = false
    
    @State private var fill = 0.0
    @State private var animatableCircleId = 0
    
    @State var tapAction: (() -> Void)
    @State var longPressingAction: ((_ isPressing: Bool) -> Void)
    
    let buttonSize = 80.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: buttonSize, height: buttonSize)
                .opacity(isLongPressing ? 0.5 : 0)
                .scaleEffect(isLongPressing || isTapped ? 1.5 : 1)
            
            Circle()
                .trim(from: 0, to: fill)
                .stroke(.linearGradient(Gradient(colors: [.red, .orange]), startPoint: .topTrailing, endPoint: .bottomLeading), lineWidth: 3)
                .rotationEffect(.degrees(-90))
                .frame(width: buttonSize - 3, height: buttonSize - 3)
                .scaleEffect(isLongPressing ? 1.5 : 1)
                .id(animatableCircleId)
            
            Circle()
                .strokeBorder(.white, lineWidth: 6)
                .frame(width: buttonSize, height: buttonSize)
                .scaleEffect(isLongPressing || isTapped ? 0.6 : 1)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: buttonSize - 20, height: buttonSize - 20)
                        .scaleEffect(isLongPressing || isTapped ? 0.75 : 1)
                )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isLongPressing || isTapped)
        .simultaneousGesture(
            // +1 second for spring animation.
            LongPressGesture(minimumDuration: .maximumVideoDuration + 1, maximumDistance: buttonSize)
                .updating($isLongPressing) { currentState, gestureState, _ in
                    gestureState = currentState
                }
        )
        .highPriorityGesture(
            TapGesture()
                .onEnded {
                    isTapped = true
                    tapAction()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTapped = false
                    }
                }
        )
        .onChange(of: isLongPressing) { isLongPressing in
            longPressingAction(isLongPressing)
            if isLongPressing {
                startStrokeAnimation()
            } else {
                resetStrokeAnimation()
            }
        }
        
    }
}

struct VideoRecordButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VideoRecordButton(tapAction: {}, longPressingAction: {_ in })
        }
    }
}

// MARK: functions
extension VideoRecordButton {
    private func startStrokeAnimation() {
        withAnimation(.linear(duration: .maximumVideoDuration)) {
            fill = 1.0
        }
    }
    
    private func resetStrokeAnimation() {
        fill = 0.0
        animatableCircleId = animatableCircleId == 0 ? 1 : 0
    }
}

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
    @State private var animationCircleId = 0
    
    @State var tapAction: (() -> Void)
    
    let buttonSize = 80.0
    let duration = StorySwiftyCamViewController.maximumVideoDuration
    
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
                .id(animationCircleId)
            
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
            LongPressGesture(minimumDuration: duration, maximumDistance: buttonSize)
                .updating($isLongPressing) { currentState, gestureState, _ in
                    gestureState = currentState
                }
        )
        .highPriorityGesture(
            TapGesture()
                .onEnded { _ in
                    isTapped = true
                    tapAction()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTapped = false
                    }
                }
        )
        .onChange(of: isLongPressing) { newValue in
            
            print("long press.")
            
            if newValue {
                startStrokeAnimation()
            } else {
                resetStrokeAnimation()
            }
        }
        
    }
}

struct VideoRecordButton_Previews: PreviewProvider {
    static var previews: some View {
        VideoRecordButton(tapAction: {})
            .preferredColorScheme(.dark)
    }
}

// MARK: functions
extension VideoRecordButton {
    func startStrokeAnimation() {
        withAnimation(.linear(duration: duration - 0.9)) {
            fill = 1.0
        }
    }
    
    func resetStrokeAnimation() {
        fill = 0.0
        animationCircleId = animationCircleId == 0 ? 1 : 0
    }
}

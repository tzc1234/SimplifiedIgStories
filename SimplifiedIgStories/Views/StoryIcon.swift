//
//  StoryIcon.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/2/2022.
//

import SwiftUI

struct StoryIcon: View {    
    @State private var endAngle = 360.0
    @ObservedObject private var tracingEndAngle = TracingEndAngle(currentEndAngle: 0.0)
    
    @State private var isAnimating = false
    @State private var isOnTap = false
    
    let animationDuration = 1.0
    
    let index: Int
    let avatar: String
    let showPlusIcon: Bool
    let onTapAction: ((Int) -> Void)
    
    init(index: Int, avatar: String, showPlusIcon: Bool, onTapAction: @escaping ((Int) -> Void)) {
        self.index = index
        self.avatar = avatar
        self.showPlusIcon = showPlusIcon
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                arc
                avatarImage
                
                if showPlusIcon {
                    plusIcon
                }
            }
            .scaledToFit()
            .scaleEffect(isOnTap ? 1.1 : 1.0)
            .frame(maxWidth: .infinity)
            .preference(key: FramePreferenceKey.self, value: geo.frame(in: .named(HomeView.coordinateSpaceName)))
            .onChange(of: tracingEndAngle.currentEndAngle) { newValue in
                if newValue == 360.0 {
                    resetStrokeAnimationAfterCompletion()
                }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    isOnTap.toggle()
                }
                
                onTapAction(index)
                isOnTap.toggle()
            }
//            .onTapGesture {
//                withAnimation(.spring()) {
//                    isOnTap.toggle()
//                }
//
//                storyGlobal.currentStoryIndex = index
//                isOnTap.toggle()
//
//                let animationDuration = 0.3
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    withAnimation(.easeInOut(duration: animationDuration)) {
//                        storyGlobal.showContainer.toggle()
//                    }
//                }
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) {
//                    storyGlobal.shouldAnimateCubicRotation = true
//                }
//            }
            
//            .onPreferenceChange(FramePreferenceKey.self) { frame in
//                storyGlobal.storyIconFrames[index] = frame
//            }
            
        }
    }
    
}

struct StoryIcon_Previews: PreviewProvider {
    static var previews: some View {
        StoryIcon(index: 0, avatar: "avatar", showPlusIcon: false, onTapAction: {_ in})
    }
}

// MARK: components
extension StoryIcon {
    var arc: some View {
        TraceableArc(startAngle: 0, endAngle: endAngle, clockwise: true, traceEndAngle: tracingEndAngle)
            .strokeBorder(
                .linearGradient(
                    colors: [.red, .orange],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                ),
                lineWidth: 10.0, antialiased: true
            )
    }
    
    var avatarImage: some View {
        GeometryReader { geo in
            Image(avatar)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: geo.size.width, height: geo.size.width, alignment: .center)
                .scaleEffect(0.9)
                .background(Circle().fill(.background).scaleEffect(0.95))
        }
    }
    
    var plusIcon: some View {
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

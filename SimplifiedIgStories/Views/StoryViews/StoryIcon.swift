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
    
    let story: Story
    let onTapAction: ((_ storyId: Int) -> Void)
    
    init(story: Story, onTapAction: @escaping ((_ storyId: Int) -> Void)) {
        self.story = story
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                arc
                avatarImage
                plusIcon
            }
            .scaledToFit()
            .scaleEffect(isOnTap ? 1.1 : 1.0)
            .frame(maxWidth: .infinity)
            .preference(
                key: IdFramePreferenceKey.self,
                value: [story.id: geo.frame(in: .named(HomeView.coordinateSpaceName))]
            )
            .onChange(of: tracingEndAngle.currentEndAngle) { newValue in
                if newValue == 360.0 { resetStrokeAnimationAfterCompletion() }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    isOnTap.toggle()
                }
                
                onTapAction(story.id)
                isOnTap.toggle()
            }
        }
    }
    
}

struct StoryIcon_Previews: PreviewProvider {
    static var previews: some View {
        let vm = StoryViewModel(dataService: MockDataService())
        StoryIcon(story: vm.stories[0], onTapAction: {_ in})
    }
}

// MARK: components
extension StoryIcon {
   private var arc: some View {
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
    
    private var avatarImage: some View {
        GeometryReader { geo in
            Image(story.user.avatar)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: geo.size.width, height: geo.size.width, alignment: .center)
                .scaleEffect(0.9)
                .background(Circle().fill(.background).scaleEffect(0.95))
        }
    }
    
    @ViewBuilder private var plusIcon: some View {
        if story.user.isCurrentUser && story.portions.count == 0 {
            Circle().fill(.blue)
                .scaledToFit()
                .background(Circle().fill(.background).scaleEffect(1.3))
                .overlay(
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .scaleEffect(0.5)
                )
                .aspectRatio(0.3, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding([.bottom, .trailing], 4)
        }
    }
}

// MARK: functions
extension StoryIcon {
    private func startStrokeAnimation() {
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
    
    private func pauseStrokeAnimation() {
        if isAnimating {
            isAnimating.toggle()
            withAnimation(.easeInOut(duration: 0)) {
                endAngle = tracingEndAngle.currentEndAngle
            }
        }
    }
    
    private func resetStrokeAnimationAfterCompletion() {
        // reset currentEndAngle to 0 after finishing animation
        tracingEndAngle.currentEndAngle = 0
        isAnimating = false
    }
}

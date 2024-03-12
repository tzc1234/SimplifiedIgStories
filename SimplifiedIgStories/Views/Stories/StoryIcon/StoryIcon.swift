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
    @State private var arcId = 0
    
    private let animationDuration = 1.0
    
    let story: Story
    let showPlusIcon: Bool
    let plusIconBgColor: Color
    let showStroke: Bool
    let onTapAction: ((_ storyId: Int) -> Void)?
    
    init(
        story: Story,
        showPlusIcon: Bool = false,
        plusIconBgColor: Color = .background,
        showStroke: Bool = true,
        onTapAction: ((_ storyId: Int) -> Void)? = nil
    ) {
        self.story = story
        self.showPlusIcon = showPlusIcon
        self.plusIconBgColor = plusIconBgColor
        self.showStroke = showStroke
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        ZStack {
            arc
            avatarImage
            plusIcon
        }
        .scaledToFit()
        .scaleEffect(isOnTap ? 1.1 : 1.0)
        .frame(maxWidth: .infinity)
        .onChange(of: tracingEndAngle.currentEndAngle) { newValue in
            if newValue == 360.0 {
                resetStrokeAnimationAfterCompletion()
            }
        }
        .onTapGesture {
            guard let onTapAction = onTapAction else { return }
            
            withAnimation(.spring()) {
                isOnTap.toggle()
            }
            
            isOnTap.toggle()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onTapAction(story.id)
            }
        }
    }
    
}

struct StoryIcon_Previews: PreviewProvider {
    static var previews: some View {
        StoryIcon(story: PreviewData.stories[0])
            .previewLayout(.sizeThatFits)
    }
}

// MARK: components
extension StoryIcon {
   @ViewBuilder private var arc: some View {
       if showStroke {
           TraceableArc(startAngle: 0, endAngle: endAngle, clockwise: true, traceEndAngle: tracingEndAngle)
               .strokeBorder(
                   .linearGradient(
                       colors: [.red, .orange],
                       startPoint: .topTrailing,
                       endPoint: .bottomLeading
                   ),
                   lineWidth: 10.0, antialiased: true
               )
               .id(arcId)
       }
    }
    
    private var avatarImage: some View {
        GeometryReader { geo in
            Image(story.user.avatar)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: geo.size.width, height: geo.size.width, alignment: .center)
                .scaleEffect(0.9)
                .background(
                    Group {
                        if showStroke {
                            Circle().fill(.background).scaleEffect(0.95)
                        }
                    }
                )
        }
    }
    
    @ViewBuilder private var plusIcon: some View {
        if showPlusIcon {
            Circle().fill(.blue)
                .scaledToFit()
                .background(
                    Circle()
                        .fill(plusIconBgColor)
                        .scaleEffect(1.3))
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

// MARK: private functions
extension StoryIcon {
    private func startStrokeAnimation() {
        if !isAnimating {
            isAnimating.toggle()
            
            // reset endAngle to 0 if the animation is finished
            if endAngle == 360 {
                endAngle = 0
            }
            
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
        tracingEndAngle.updateEndAngle(0)
        isAnimating = false
    }
    
    private func resetAnimation() {
        arcId = arcId == 0 ? 1 : 0
        tracingEndAngle.updateEndAngle(0)
    }
}

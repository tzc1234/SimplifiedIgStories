//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryView: View {
    let story: Story
    @ObservedObject private var vm: StoryViewModel
    
    init(story: Story, storyViewModel: StoryViewModel) {
        self.story = story
        self.vm = storyViewModel
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(alignment: .leading) {
                    ProgressBar(story: story, storyViewModel: vm)
                        .frame(height: 2.0, alignment: .center)
                        .padding(.top, 8.0)
                    
                    HStack {
                        avatarIcon
                        nameText
                        dateText
                        Spacer()
                        closeButton
                    }
                    .padding(.leading, 20.0)
                    
                    Spacer()
                    
                    DetectableTapGesturePositionView(
                        tapCallback: vm.decidePortionTransitionDirectionBy(point:)
                    )
                    
                    Spacer()
                    
                    Button {
                        print("more.")
                    } label: {
                        Label("More", systemImage: "ellipsis")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .labelStyle(.verticalLabelStyle)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding([.bottom, .horizontal])
                    
                }
            }
            .background(
                Group {
                    let frame = geo.frame(in: .global)
                    storyPortionViews
                        .clipShape(Rectangle())
                        .preference(key: FramePreferenceKey.self, value: frame)
                        .onPreferenceChange(FramePreferenceKey.self) { preferenceFrame in
                            vm.storiesViewModel.shouldAnimateCubicRotation =
                            preferenceFrame.width == UIScreen.main.bounds.width
                        }
                }
            )
            .onAppear {
                vm.initAnimation(story: story)
                print(geo.safeAreaInsets)
            }
            .cubicTransition(
                shouldRotate: vm.storiesViewModel.shouldAnimateCubicRotation,
                offsetX: geo.frame(in: .global).minX
            )
            
        }
    }
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel()
        let story = storiesViewModel.atLeastOnePortionStories[0]
        StoryView(
            story: story,
            storyViewModel: storiesViewModel.getStoryViewModelBy(story: story)
        )
    }
}

// MARK: components
extension StoryView {
    // TODO: Limit the number of StoryPortionViews.
    private var storyPortionViews: some View {
        ZStack(alignment: .top) {
            ForEach(story.portions) { portion in
                if portion.id == vm.currentStoryPortionId {
                    StoryPortionView(
                        portion: portion,
                        storyViewModel: vm
                    )
                }
            }
        }
    }
    
    private var avatarIcon: some View {
        var onTapAction: ((Int) -> Void)?
        if story.user.isCurrentUser {
            onTapAction = { _ in
                vm.storiesViewModel.closeStoryContainer()
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.3,
                    execute: vm.storiesViewModel.toggleStoryCamView
                )
            }
        }
        
        return StoryIcon(
            story: story,
            showPlusIcon: story.user.isCurrentUser,
            plusIconBgColor: .white,
            showStroke: false,
            onTapAction: onTapAction
        )
            .frame(width: 40.0, height: 40.0)
    }
    
    private var nameText: some View {
        Text(story.user.title)
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    private var dateText: some View {
        Text(story.lastUpdateDate?.timeAgoDisplay() ?? "")
            .foregroundColor(.white)
            .font(.subheadline)
    }
    
    private var closeButton: some View {
        Button(action: vm.storiesViewModel.closeStoryContainer) {
            ZStack {
                // Increase close button tap area.
                Color.clear.frame(width: 45.0, height: 45.0)
                Image(systemName: "xmark")
                    .resizable()
                    .foregroundColor(.white)
                    .frame(width: 25.0, height: 25.0)
            }
            .contentShape(Rectangle())
        }
        .padding(.trailing, 10.0)
    }
}

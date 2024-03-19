//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryView: View {
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    
    let story: Story
    let shouldCubicRotation: Bool
    @StateObject var storyViewModel: StoryViewModel
    @StateObject var animationHandler: StoryAnimationHandler
    let getProgressBar: () -> ProgressBar
    let onDisappear: (Int) -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(alignment: .leading) {
                    getProgressBar()
                        .frame(height: 2.0, alignment: .center)
                        .padding(.top, 12.0)
                    
                    HStack {
                        avatarIcon
                        nameText
                        dateText
                        Spacer()
                        closeButton
                    }
                    .padding(.leading, 20.0)
                    
                    Spacer()
                    
                    DetectableTapGesturePositionView { point in
                        animationHandler.setPortionTransitionDirection(by: point.x)
                    }
                    
                    Spacer()
                    
                    moreButton
                        .confirmationDialog("", isPresented: $storyViewModel.showConfirmationDialog, titleVisibility: .hidden) {
                            Button("Delete", role: .destructive) {
                                storyViewModel.deleteCurrentPortion {
                                    homeUIActionHandler.closeStoryContainer(storyId: story.id)
                                }
                            }
                            Button("Save", role: .none) {
                                Task {
                                    await storyViewModel.savePortionImageVideo()
                                }
                            }
                            Button("Cancel", role: .cancel, action: {})
                        }
                }
                
                LoadingView()
                    .opacity(storyViewModel.isLoading ? 1 : 0)
                
                noticeLabel
            }
            .background(storyPortionViews)
            .onAppear {
                print("storyId: \(story.id) view onAppear.")
                animationHandler.startProgressBarAnimation()
            }
            .cubicTransition(
                shouldRotate: shouldCubicRotation,
                offsetX: geo.frame(in: .global).minX
            )
            .onDisappear {
                print("storyId: \(story.id) view onDisappear.")
                onDisappear(story.id)
            }
        }
    }
}

extension StoryView {
    private var storyPortionViews: some View {
        ZStack {
            ForEach(story.portions) { portion in
                if portion.id == animationHandler.currentPortionId {
                    StoryPortionView(
                        portion: portion,
                        animationHandler: animationHandler
                    )
                }
            }
        }
        .clipShape(Rectangle())
    }
    
    private var avatarIcon: some View {
        var onTapAction: ((Story) -> Void)?
        if story.user.isCurrentUser {
            onTapAction = { _ in
                homeUIActionHandler.closeStoryContainer(storyId: story.id)
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.3,
                    execute: homeUIActionHandler.toggleStoryCamView
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
        Text(story.lastUpdate?.timeAgoDisplay() ?? "")
            .foregroundColor(.white)
            .font(.subheadline)
    }
    
    private var closeButton: some View {
        Button {
            homeUIActionHandler.closeStoryContainer(storyId: story.id)
        } label: {
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
    
    @ViewBuilder 
    private var moreButton: some View {
        if story.user.isCurrentUser {
            Button {
                storyViewModel.showConfirmationDialog.toggle()
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
    
    private var noticeLabel: some View {
        NoticeLabel(message: storyViewModel.noticeMsg)
            .opacity(storyViewModel.showNoticeLabel ? 1 : 0)
            .animation(.easeIn, value: storyViewModel.showNoticeLabel)
    }
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel.preview
        let story = storiesViewModel.currentStories[0]
        StoryView.preview(story: story, parentViewModel: storiesViewModel)
    }
}

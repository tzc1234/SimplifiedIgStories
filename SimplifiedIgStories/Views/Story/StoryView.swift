//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryView: View {
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    
    let storyId: Int
    @StateObject var storyViewModel: StoryViewModel
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(alignment: .leading) {
                    ProgressBar(storyId: storyId, storyViewModel: storyViewModel)
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
                        storyViewModel.setPortionTransitionDirection(by: point.x)
                    }
                    
                    Spacer()
                    
                    moreButton
                        .confirmationDialog("", isPresented: $storyViewModel.showConfirmationDialog, titleVisibility: .hidden) {
                            Button("Delete", role: .destructive) {
                                storyViewModel.deleteCurrentPortion {
                                    homeUIActionHandler.closeStoryContainer(storyId: storyId)
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
                print("storyId: \(storyId) view onAppear.")
                storyViewModel.startProgressBarAnimation()
            }
            .cubicTransition(
                shouldRotate: storyViewModel.shouldCubicRotation,
                offsetX: geo.frame(in: .global).minX
            )
            .onDisappear {
                print("storyId: \(storyId) view onDisappear.")
            }
        }
    }
}

extension StoryView {
    private var storyPortionViews: some View {
        ZStack {
            ForEach(storyViewModel.portions) { portion in
                if portion.id == storyViewModel.currentPortionId {
                    StoryPortionView(
                        portion: portion,
                        storyViewModel: storyViewModel
                    )
                }
            }
        }
        .clipShape(Rectangle())
    }
    
    private var avatarIcon: some View {
        var onTapAction: ((Story) -> Void)?
        if storyViewModel.story.user.isCurrentUser {
            onTapAction = { _ in
                homeUIActionHandler.closeStoryContainer(storyId: storyId)
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.3,
                    execute: homeUIActionHandler.toggleStoryCamView
                )
            }
        }
        
        return StoryIcon(
            story: storyViewModel.story,
            showPlusIcon: storyViewModel.story.user.isCurrentUser,
            plusIconBgColor: .white,
            showStroke: false,
            onTapAction: onTapAction
        )
        .frame(width: 40.0, height: 40.0)
    }
    
    private var nameText: some View {
        Text(storyViewModel.story.user.title)
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    private var dateText: some View {
        Text(storyViewModel.story.lastUpdate?.timeAgoDisplay() ?? "")
            .foregroundColor(.white)
            .font(.subheadline)
    }
    
    private var closeButton: some View {
        Button {
            homeUIActionHandler.closeStoryContainer(storyId: storyId)
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
        if storyViewModel.story.user.isCurrentUser {
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
        StoryView.preview(storyId: story.id, parentViewModel: storiesViewModel)
    }
}

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
    @StateObject var vm: StoryViewModel // Injected from StoryContainer
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(alignment: .leading) {
                    ProgressBar(storyId: storyId, storyViewModel: vm)
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
                        vm.decidePortionTransitionDirection(by: point.x)
                    }
                    
                    Spacer()
                    
                    moreButton
                        .confirmationDialog("", isPresented: $vm.showConfirmationDialog, titleVisibility: .hidden) {
                            Button("Delete", role: .destructive) {
                                vm.deleteCurrentPortion {
                                    homeUIActionHandler.closeStoryContainer(storyId: storyId)
                                }
                            }
                            Button("Save", role: .none) {
                                Task {
                                    await vm.savePortionImageVideo()
                                }
                            }
                            Button("Cancel", role: .cancel, action: {})
                        }
                }
                
                if vm.isLoading { LoadingView() }
                
                noticeLabel
            }
            .background(
                Group {
                    let frame = geo.frame(in: .global)
                    storyPortionViews
                        .preference(key: FramePreferenceKey.self, value: frame)
                        .onPreferenceChange(FramePreferenceKey.self) { preferenceFrame in
                            vm.storiesViewModel.shouldCubicRotation =
                            preferenceFrame.width == .screenWidth
                        }
                }
            )
            .onAppear {
                vm.initStoryAnimation(by: storyId)
            }
            .cubicTransition(
                shouldRotate: vm.storiesViewModel.shouldCubicRotation,
                offsetX: geo.frame(in: .global).minX
            )
            .onDisappear {
                print("storyId: \(storyId) view onDisappear.")
            }
        }
        
    }
    
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel(fileManager: LocalFileManager())
        let story = storiesViewModel.currentStories[0]
        StoryView(
            storyId: story.id,
            vm: StoryViewModel(
                storyId: story.id,
                storiesViewModel: storiesViewModel,
                fileManager: LocalFileManager()
            )
        )
    }
}

// MARK: components
extension StoryView {
    // TODO: Limit the number of StoryPortionViews.
    private var storyPortionViews: some View {
        ZStack {
            ForEach(vm.story.portions) { portion in
                if portion.id == vm.currentPortionId {
                    StoryPortionView(
                        portion: portion,
                        storyViewModel: vm
                    )
                }
            }
        }
        .clipShape(Rectangle())
    }
    
    private var avatarIcon: some View {
        var onTapAction: ((Int) -> Void)?
        if vm.story.user.isCurrentUser {
            onTapAction = { _ in
                homeUIActionHandler.closeStoryContainer(storyId: storyId)
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.3,
                    execute: homeUIActionHandler.toggleStoryCamView
                )
            }
        }
        
        return StoryIcon(
            story: vm.story,
            showPlusIcon: vm.story.user.isCurrentUser,
            plusIconBgColor: .white,
            showStroke: false,
            onTapAction: onTapAction
        )
            .frame(width: 40.0, height: 40.0)
    }
    
    private var nameText: some View {
        Text(vm.story.user.title)
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    private var dateText: some View {
        Text(vm.story.lastUpdateDate?.timeAgoDisplay() ?? "")
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
    
    @ViewBuilder private var moreButton: some View {
        if vm.story.user.isCurrentUser {
            Button {
                vm.showConfirmationDialog.toggle()
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
        NoticeLabel(message: vm.noticeMsg)
            .opacity(vm.showNoticeLabel ? 1 : 0)
            .animation(.easeIn, value: vm.showNoticeLabel)
    }
}

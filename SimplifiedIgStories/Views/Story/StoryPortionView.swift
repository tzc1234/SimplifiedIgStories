//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI
import AVKit

protocol PortionMutationHandler {
    func deleteCurrentPortion(for portionId: Int,
                              afterDeletion: (_ portionIndex: Int) -> Void,
                              whenNoNextPortionAfterDeletion: () -> Void)
    func savePortionMedia(for portionId: Int) async -> String
}

// *** In real environment, images are loaded through internet. The failure case should be considered.
struct StoryPortionView: View {
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    @State private var player: AVPlayer?
    @State private var isLoading = false
    
    let portion: Portion
    @ObservedObject var storyViewModel: StoryViewModel
    @ObservedObject var animationHandler: StoryAnimationHandler
    let portionMutationHandler: PortionMutationHandler
    
    private var story: Story {
        storyViewModel.story
    }
    
    var body: some View {
        ZStack {
            Color.darkGray
            photoView
            videoView
            
            DetectableTapGesturePositionView { point in
                animationHandler.performPortionTransitionAnimation(by: point.x)
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    moreButton
                        .confirmationDialog("", isPresented: $storyViewModel.showConfirmationDialog, titleVisibility: .hidden) {
                            Button("Delete", role: .destructive) {
                                portionMutationHandler.deleteCurrentPortion(
                                    for: portion.id,
                                    afterDeletion: { portionIndex in
                                        animationHandler.moveToCurrentPortion(for: portionIndex)
                                    },
                                    whenNoNextPortionAfterDeletion: {
                                        homeUIActionHandler.closeStoryContainer(storyId: story.id)
                                    })
                            }
                            
                            Button("Save", role: .none) {
                                Task {
                                    isLoading = true
                                    let message = await portionMutationHandler.savePortionMedia(for: portion.id)
                                    
                                    isLoading = false
                                    storyViewModel.showNotice(message: message)
                                }
                            }
                            
                            Button("Cancel", role: .cancel, action: {})
                        }
                }
            }
            
            LoadingView()
                .opacity(isLoading ? 1 : 0)
            
            noticeLabel
        }
        .onAppear {
            player = portion.videoURL.map(AVPlayer.init)
        }
        .onChange(of: animationHandler.barPortionAnimationStatusDict[portion.id]) { status in
            guard let player else { return }
            
            switch status {
            case .initial:
                player.reset()
            case .start, .restart:
                player.replay()
            case .pause:
                player.pause()
            case .resume:
                player.play()
            case .finish:
                player.finish()
            case .none:
                break
            }
        }
    }
}

extension StoryPortionView {
    @ViewBuilder
    private var photoView: some View {
        AsyncImage(url: portion.imageURL) { image in
            ZStack {
                GeometryReader { _ in
                    image
                        .resizable()
                        .scaledToFill()
                        .overlay(.ultraThinMaterial)
                        .clipShape(Rectangle())
                }
                
                image
                    .resizable()
                    .scaledToFit()
            }
        } placeholder: {
            Color.darkGray
        }
    }
    
    @ViewBuilder 
    private var videoView: some View {
        if player != nil {
            AVPlayerControllerRepresentable(
                shouldLoop: false,
                player: player
            )
        }
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
            .padding([.bottom, .horizontal])
            .background(Color.blue.opacity(0.01))
        }
    }
    
    private var noticeLabel: some View {
        NoticeLabel(message: storyViewModel.noticeMsg)
            .opacity(storyViewModel.noticeMsg.isEmpty ? 0 : 1)
            .animation(.easeIn, value: storyViewModel.noticeMsg)
    }
}

struct StoryPortionView_Previews: PreviewProvider {
    static var previews: some View {
        let story = PreviewData.stories[0]
        let portion = story.portions[0]
        StoryPortionView(
            portion: portion,
            storyViewModel: StoryViewModel(story: story),
            animationHandler: .preview,
            portionMutationHandler: StoriesViewModel.preview
        )
    }
}

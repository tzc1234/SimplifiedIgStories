//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI
import AVKit
import Combine

// *** In real environment, images are loaded through internet. The failure case should be considered.
struct StoryPortionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    @State private var player: AVPlayer?
    
    let portionIndex: Int
    @ObservedObject var storyPortionViewModel: StoryPortionViewModel
    @ObservedObject var animationHandler: StoryAnimationHandler
    let deletePortion: (Int, () -> Void, () -> Void) -> Void
    let onDisappear: (Int) -> Void
    
    private var portion: PortionDTO {
        storyPortionViewModel.portion
    }
    
    private var animationShouldPausePublisher: AnyPublisher<Bool, Never> {
        storyPortionViewModel.$showConfirmationDialog
            .combineLatest(storyPortionViewModel.$noticeMessage)
            .map { $0 || !$1.isEmpty }
            .dropFirst()
            .removeDuplicates()
            .eraseToAnyPublisher()
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
                        .confirmationDialog("", isPresented: $storyPortionViewModel.showConfirmationDialog, titleVisibility: .hidden) {
                            if storyPortionViewModel.isCurrentUser {
                                Button("Delete", role: .destructive) {
                                    storyPortionViewModel.deletePortionMedia()
                                    deletePortion(portion.id, {
                                        animationHandler.moveCurrentPortion(at: portionIndex)
                                    }, {
                                        homeUIActionHandler.closeStoryContainer(storyId: storyPortionViewModel.storyId)
                                    })
                                }
                            }
                            
                            Button("Save", role: .none) {
                                Task {
                                    await storyPortionViewModel.saveMedia()
                                }
                            }
                            
                            Button("Cancel", role: .cancel, action: {})
                        }
                }
            }
            
            LoadingView()
                .opacity(storyPortionViewModel.isLoading ? 1 : 0)
            
            noticeLabel
        }
        .onAppear {
            player = portion.videoURL.map(AVPlayer.init)
        }
        .onChange(of: animationHandler.portionAnimationStatusDict[portionIndex]) { status in
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                animationHandler.resumePortionAnimation()
            } else if newPhase == .inactive {
                animationHandler.pausePortionAnimation()
            }
        }
        .onReceive(animationShouldPausePublisher, perform: { shouldPause in
            if shouldPause {
                animationHandler.pausePortionAnimation()
            } else {
                animationHandler.resumePortionAnimation()
            }
        })
        .onDisappear {
            onDisappear(portion.id)
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
    
    private var moreButton: some View {
        Button {
            storyPortionViewModel.showConfirmationDialog.toggle()
        } label: {
            Label("More", systemImage: "ellipsis")
                .foregroundColor(.white)
                .font(.subheadline)
                .labelStyle(.verticalLabelStyle)
        }
        .padding([.bottom, .horizontal])
        .background(Color.blue.opacity(0.01))
        
    }
    
    private var noticeLabel: some View {
        NoticeLabel(message: storyPortionViewModel.noticeMessage)
            .opacity(storyPortionViewModel.noticeMessage.isEmpty ? 0 : 1)
            .animation(.easeIn, value: storyPortionViewModel.noticeMessage)
    }
}

struct StoryPortionView_Previews: PreviewProvider {
    static var previews: some View {
        StoryPortionView.preview
    }
}

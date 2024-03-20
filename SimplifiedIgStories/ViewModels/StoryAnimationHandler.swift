//
//  StoryAnimationHandler.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 14/03/2024.
//

import Foundation
import Combine

enum BarPortionAnimationStatus: CaseIterable {
    case initial, start, restart, pause, resume, finish
}

protocol CurrentStoryHandler {
    var firstCurrentStoryId: Int? { get }
    var isAtLastStory: Bool { get }
    var currentStoryId: Int { get }
    var stories: [Story] { get }
    var isSameStoryAfterDragging: Bool { get }
    
    func moveToPreviousStory()
    func moveToNextStory()
    func getIsDraggingPublisher() -> AnyPublisher<Bool, Never>
}

final class StoryAnimationHandler: ObservableObject {
    typealias PortionId = Int
    
    @Published private(set) var barPortionAnimationStatusDict = [PortionId: BarPortionAnimationStatus]()
    @Published private(set) var currentPortionId: PortionId = -1
    private var isDragging = false
    private var subscriptions = Set<AnyCancellable>()
    
    let storyId: Int
    private let currentStoryHandler: CurrentStoryHandler
    private let animationShouldPausePublisher: AnyPublisher<Bool, Never>
    
    init(storyId: Int,
         currentStoryHandler: CurrentStoryHandler,
         animationShouldPausePublisher: AnyPublisher<Bool, Never>) {
        self.storyId = storyId
        self.currentStoryHandler = currentStoryHandler
        self.animationShouldPausePublisher = animationShouldPausePublisher
        
        if let firstPortionId = portions.first?.id {
            self.currentPortionId = firstPortionId
            self.initBarPortionAnimationStatus()
        }
        
        self.subscribePublishers()
    }
}

extension StoryAnimationHandler {
    var currentPortionAnimationStatus: BarPortionAnimationStatus? {
        barPortionAnimationStatusDict[currentPortionId]
    }
    
    private var isCurrentPortionAnimating: Bool {
        currentPortionAnimationStatus == .start ||
        currentPortionAnimationStatus == .restart ||
        currentPortionAnimationStatus == .resume
    }
    
    private var isAtFirstStory: Bool {
        currentStoryHandler.firstCurrentStoryId == storyId
    }
    
    private var isCurrentStory: Bool {
        currentStoryHandler.currentStoryId == storyId
    }
    
    private var portions: [Portion] {
        currentStoryHandler.stories.first(where: { $0.id == storyId })?.portions ?? []
    }
    
    var currentPortionIndex: Int? {
        portions.firstIndex(where: { $0.id == currentPortionId })
    }
    
    private var isAtFirstPortion: Bool {
        currentPortionId == portions.first?.id
    }
    
    private var isAtLastPortion: Bool {
        currentPortionId == portions.last?.id
    }
}

extension StoryAnimationHandler {
    private func initBarPortionAnimationStatus() {
        setCurrentBarPortionAnimationStatus(to: .initial)
    }
    
    private func setCurrentBarPortionAnimationStatus(to status: BarPortionAnimationStatus) {
        barPortionAnimationStatusDict[currentPortionId] = status
    }
    
    private func subscribePublishers() {
        currentStoryHandler.getIsDraggingPublisher()
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] dragging in
                guard let self else { return }
                
                isDragging = dragging
                if dragging {
                    pausePortionAnimation()
                } else {
                    resumePortionAnimationIfStayAtSameStoryAfterDragged()
                }
            }
            .store(in: &subscriptions)
        
        animationShouldPausePublisher
            .sink { [weak self] shouldPause in
                guard let self else { return }
                
                if shouldPause {
                    pausePortionAnimation()
                } else if !isDragging {
                    resumePortionAnimation()
                }
            }
            .store(in: &subscriptions)
    }
    
    func setPortionTransitionDirection(by pointX: CGFloat) {
        if pointX <= .screenWidth/2 {
            performBackwardPortionAnimation()
        } else {
            performForwardPortionAnimation()
        }
    }
    
    private func performBackwardPortionAnimation() {
        if isAtFirstPortion {
            if isAtFirstStory {
                restartPortionAnimation()
            } else { // Not at the first story (that means the previous story must exist.)
                setCurrentBarPortionAnimationStatus(to: .initial)
                currentStoryHandler.moveToPreviousStory()
            }
        } else {
            setCurrentBarPortionAnimationStatus(to: .initial)
            moveToPreviewPortion()
        }
    }
    
    private func restartPortionAnimation() {
        setCurrentBarPortionAnimationStatus(to: currentPortionAnimationStatus == .start ? .restart : .start)
    }
    
    private func moveToPreviewPortion() {
        guard let currentPortionIndex else { return }
        
        let previousPortionIndex = currentPortionIndex-1
        if previousPortionIndex >= 0 {
            currentPortionId = portions[previousPortionIndex].id
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func performForwardPortionAnimation() {
        // Will trigger the onChange of currentPortionAnimationStatus in ProgressBar.
        setCurrentBarPortionAnimationStatus(to: .finish)
    }
    
    func startProgressBarAnimation() {
        guard isCurrentStory && !isCurrentPortionAnimating else { return }
        
        setCurrentBarPortionAnimationStatus(to: .start)
    }
    
    func pausePortionAnimation() {
        if isCurrentStory && isCurrentPortionAnimating {
            setCurrentBarPortionAnimationStatus(to: .pause)
        }
    }
    
    func resumePortionAnimation() {
        if isCurrentStory && currentPortionAnimationStatus == .pause {
            setCurrentBarPortionAnimationStatus(to: .resume)
        }
    }
    
    func finishPortionAnimation(for portionId: PortionId) {
        barPortionAnimationStatusDict[portionId] = .finish
    }
    
    func moveToCurrentPortion(for portionIndex: Int) {
        guard portionIndex < portions.count else { return }
        
        currentPortionId = portions[portionIndex].id
        setCurrentBarPortionAnimationStatus(to: .start)
    }
    
    func performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory action: () -> Void) {
        guard currentPortionAnimationStatus == .finish else { return }
        
        if isAtLastPortion {
            if currentStoryHandler.isAtLastStory {
                action()
            } else {
                currentStoryHandler.moveToNextStory()
            }
        } else {
            moveToNextPortion()
        }
    }
    
    private func moveToNextPortion() {
        guard let currentPortionIndex else { return }
        
        let nextPortionIndex = currentPortionIndex+1
        if nextPortionIndex < portions.count {
            currentPortionId = portions[nextPortionIndex].id
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func resumePortionAnimationIfStayAtSameStoryAfterDragged() {
        if currentStoryHandler.isSameStoryAfterDragging {
            resumePortionAnimation()
        }
    }
}

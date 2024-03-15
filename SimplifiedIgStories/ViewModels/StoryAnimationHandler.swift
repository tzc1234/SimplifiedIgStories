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

final class StoryAnimationHandler: ObservableObject {
    enum PortionTransitionDirection {
        case forward, backward
    }
    
    @Published private var portionTransitionDirection = PortionTransitionDirection.forward
    @Published private(set) var barPortionAnimationStatusDict = [Int: BarPortionAnimationStatus]()
    
    private var subscriptions = Set<AnyCancellable>()
    
    var currentPortionAnimationStatus: BarPortionAnimationStatus? {
        barPortionAnimationStatusDict[currentPortionId]
    }
    
    private var isCurrentPortionAnimating: Bool {
        currentPortionAnimationStatus == .start ||
        currentPortionAnimationStatus == .restart ||
        currentPortionAnimationStatus == .resume
    }
    
    var currentPortionIndex: Int? {
        portions().firstIndex(where: { $0.id == currentPortionId })
    }
    
    var currentPortion: Portion? {
        portions().first(where: { $0.id == currentPortionId })
    }
    
    private var isAtFirstPortion: Bool {
        currentPortionId == portions().first?.id
    }
    
    private var isAtLastPortion: Bool {
        currentPortionId == portions().last?.id
    }
    
    @Published private(set) var currentPortionId: Int
    private let isAtFirstStory: () -> Bool
    private let isAtLastStory: () -> Bool
    private let isCurrentStory: () -> Bool
    private let moveToPreviousStory: () -> Void
    private let moveToNextStory: () -> Void
    private let portions: () -> [Portion]
    private let isSameStoryAfterDragging: () -> Bool
    private let isDraggingPublisher: () -> AnyPublisher<Bool, Never>
    private let animationShouldPausePublisher: () -> AnyPublisher<Bool, Never>
    
    init(isAtFirstStory: @escaping () -> Bool,
         isAtLastStory: @escaping () -> Bool,
         isCurrentStory: @escaping () -> Bool,
         moveToPreviousStory: @escaping () -> Void,
         moveToNextStory: @escaping () -> Void,
         portions: @escaping () -> [Portion],
         isSameStoryAfterDragging: @escaping () -> Bool,
         isDraggingPublisher: @escaping () -> AnyPublisher<Bool, Never>,
         animationShouldPausePublisher: @escaping () -> AnyPublisher<Bool, Never>) {
        self.isAtFirstStory = isAtFirstStory
        self.isAtLastStory = isAtLastStory
        self.isCurrentStory = isCurrentStory
        self.moveToPreviousStory = moveToPreviousStory
        self.moveToNextStory = moveToNextStory
        self.portions = portions
        self.isSameStoryAfterDragging = isSameStoryAfterDragging
        self.isDraggingPublisher = isDraggingPublisher
        self.animationShouldPausePublisher = animationShouldPausePublisher
        self.currentPortionId = portions().first?.id ?? -1
        
        self.initBarPortionAnimationStatus()
        self.subscribePublishers()
    }
    
    private func initBarPortionAnimationStatus() {
        setCurrentBarPortionAnimationStatus(to: .initial)
    }
    
    private func setCurrentBarPortionAnimationStatus(to status: BarPortionAnimationStatus) {
        barPortionAnimationStatusDict[currentPortionId] = status
    }
    
    private func subscribePublishers() {
        $portionTransitionDirection
            .dropFirst()
            .sink { [weak self] direction in
                switch direction {
                case .forward:
                    self?.performForwardPortionAnimation()
                case .backward:
                    self?.performBackwardPortionAnimation()
                }
            }
            .store(in: &subscriptions)
        
        isDraggingPublisher()
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] dragging in
                self?.updateBarPortionAnimationStatusWhenDragging(dragging)
            }
            .store(in: &subscriptions)
        
        animationShouldPausePublisher()
            .sink { [weak self] shouldPause in
                shouldPause ? self?.pausePortionAnimation() : self?.resumePortionAnimation()
            }
            .store(in: &subscriptions)
    }
    
    func setPortionTransitionDirection(by pointX: CGFloat) {
        portionTransitionDirection = pointX <= .screenWidth/2 ? .backward : .forward
    }
    
    func startProgressBarAnimation() {
        guard isCurrentStory() && !isCurrentPortionAnimating else { return }
        
        setCurrentBarPortionAnimationStatus(to: .start)
    }
    
    func pausePortionAnimation() {
        if isCurrentStory() && isCurrentPortionAnimating {
            setCurrentBarPortionAnimationStatus(to: .pause)
        }
    }
    
    func resumePortionAnimation() {
        if isCurrentStory() && currentPortionAnimationStatus == .pause {
            setCurrentBarPortionAnimationStatus(to: .resume)
        }
    }
    
    func finishPortionAnimation(for portionId: Int) {
        barPortionAnimationStatusDict[portionId] = .finish
    }
    
    private func performForwardPortionAnimation() {
        // Will trigger the onChange of currentPortionAnimationStatus in ProgressBar.
        setCurrentBarPortionAnimationStatus(to: .finish)
    }
    
    private func performBackwardPortionAnimation() {
        if isAtFirstPortion {
            if isAtFirstStory() {
                restartPortionAnimation()
            } else { // Not at the first story (that means the previous story must exist.)
                setCurrentBarPortionAnimationStatus(to: .initial)
                moveToPreviousStory()
            }
        } else {
            setCurrentBarPortionAnimationStatus(to: .initial)
            moveToPreviewPortion()
        }
    }
    
    private func restartPortionAnimation() {
        setCurrentBarPortionAnimationStatus(to: currentPortionAnimationStatus == .start ? .restart : .start)
    }
    
    func performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory action: () -> Void) {
        guard currentPortionAnimationStatus == .finish else { return }
        
        if isAtLastPortion {
            if isAtLastStory() {
                action()
            } else {
                moveToNextStory()
            }
        } else {
            moveToNextPortion()
        }
    }
    
    private func moveToPreviewPortion() {
        guard let currentPortionIndex else { return }
        
        let previousPortionIndex = currentPortionIndex-1
        if previousPortionIndex >= 0 {
            currentPortionId = portions()[previousPortionIndex].id
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func moveToNextPortion() {
        guard let currentPortionIndex else { return }
        
        let nextPortionIndex = currentPortionIndex+1
        if nextPortionIndex < portions().count {
            currentPortionId = portions()[nextPortionIndex].id
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func updateBarPortionAnimationStatusWhenDragging(_ isDragging: Bool) {
        if isDragging {
            pausePortionAnimation()
        } else if isSameStoryAfterDragging() {
            resumePortionAnimation()
        }
    }
    
    func moveToNewCurrentPortion(for portionIndex: Int) {
        currentPortionId = portions()[portionIndex].id
        setCurrentBarPortionAnimationStatus(to: .start)
    }
}

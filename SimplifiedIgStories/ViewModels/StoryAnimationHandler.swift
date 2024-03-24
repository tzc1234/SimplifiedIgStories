//
//  StoryAnimationHandler.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 14/03/2024.
//

import Foundation
import Combine

enum PortionAnimationStatus {
    case initial, start, restart, pause, resume, finish
}

protocol CurrentStoryAnimationHandler {
    var objectWillChange: ObservableObjectPublisher { get }
    var isAtFirstStory: Bool { get }
    var isAtLastStory: Bool { get }
    var currentStoryId: Int { get }
    var isSameStoryAfterDragging: Bool { get }
    
    func getPortions(by storyId: Int) -> [Portion]
    func moveToPreviousStory()
    func moveToNextStory()
    func getIsDraggingPublisher() -> AnyPublisher<Bool, Never>
}

final class StoryAnimationHandler: ObservableObject {
    @Published private(set) var portionAnimationStatusDict = [Int: PortionAnimationStatus]()
    @Published private(set) var currentPortionIndex: Int = 0
    
    private var subscriptions = Set<AnyCancellable>()
    
    let storyId: Int
    private let currentStoryAnimationHandler: CurrentStoryAnimationHandler
    
    init(storyId: Int, currentStoryAnimationHandler: CurrentStoryAnimationHandler) {
        self.storyId = storyId
        self.currentStoryAnimationHandler = currentStoryAnimationHandler
        self.initBarPortionAnimationStatus()
        self.subscribePublishers()
    }
    
    deinit{
        print("\(String(describing: Self.self)) storyId: \(storyId) deinit.")
    }
}

extension StoryAnimationHandler {
    var currentStoryId: Int {
        currentStoryAnimationHandler.currentStoryId
    }
    
    var currentPortionAnimationStatus: PortionAnimationStatus? {
        portionAnimationStatusDict[currentPortionIndex]
    }
    
    private var isCurrentPortionAnimating: Bool {
        currentPortionAnimationStatus == .start ||
        currentPortionAnimationStatus == .restart ||
        currentPortionAnimationStatus == .resume
    }
    
    private var isCurrentStory: Bool {
        currentStoryId == storyId
    }
    
    private var portions: [Portion] {
        currentStoryAnimationHandler.getPortions(by: storyId)
    }
    
    private var isAtFirstPortion: Bool {
        currentPortionIndex == 0
    }
    
    private var isAtLastPortion: Bool {
        currentPortionIndex == portions.count - 1
    }
}

extension StoryAnimationHandler {
    private func initBarPortionAnimationStatus() {
        guard !portions.isEmpty else { return }
        
        setCurrentBarPortionAnimationStatus(to: .initial)
    }
    
    private func setCurrentBarPortionAnimationStatus(to status: PortionAnimationStatus) {
        portionAnimationStatusDict[currentPortionIndex] = status
    }
    
    private func subscribePublishers() {
        currentStoryAnimationHandler.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)
        
        currentStoryAnimationHandler.getIsDraggingPublisher()
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] dragging in
                if dragging {
                    self?.pausePortionAnimation()
                } else {
                    self?.resumePortionAnimationIfStayAtSameStoryAfterDragged()
                }
            }
            .store(in: &subscriptions)
    }
    
    func performPortionTransitionAnimation(by pointX: CGFloat) {
        if pointX <= .screenWidth/2 {
            performBackwardPortionAnimation()
        } else {
            performForwardPortionAnimation()
        }
    }
    
    private func performBackwardPortionAnimation() {
        if isAtFirstPortion {
            if currentStoryAnimationHandler.isAtFirstStory {
                restartPortionAnimation()
            } else { // Not at the first story (that means the previous story must exist.)
                setCurrentBarPortionAnimationStatus(to: .initial)
                currentStoryAnimationHandler.moveToPreviousStory()
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
        let previousPortionIndex = currentPortionIndex-1
        if previousPortionIndex >= 0 {
            currentPortionIndex = previousPortionIndex
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
        guard isCurrentPortionAnimating else { return }
        
        setCurrentBarPortionAnimationStatus(to: .pause)
    }
    
    func resumePortionAnimation() {
        guard currentPortionAnimationStatus == .pause else { return }
        
        setCurrentBarPortionAnimationStatus(to: .resume)
    }
    
    func finishPortionAnimation(at portionIndex: Int) {
        portionAnimationStatusDict[portionIndex] = .finish
    }
    
    func moveToCurrentPortion(for portionIndex: Int) {
        guard portionIndex < portions.count else { return }
        
        currentPortionIndex = portionIndex
        setCurrentBarPortionAnimationStatus(to: .start)
    }
    
    func performNextPortionAnimationWhenCurrentPortionFinished(whenNoNextStory action: () -> Void) {
        guard currentPortionAnimationStatus == .finish else { return }
        
        if isAtLastPortion {
            if currentStoryAnimationHandler.isAtLastStory {
                action()
            } else {
                currentStoryAnimationHandler.moveToNextStory()
            }
        } else {
            moveToNextPortion()
        }
    }
    
    private func moveToNextPortion() {
        let nextPortionIndex = currentPortionIndex+1
        if nextPortionIndex < portions.count {
            currentPortionIndex = nextPortionIndex
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func resumePortionAnimationIfStayAtSameStoryAfterDragged() {
        if currentStoryAnimationHandler.isSameStoryAfterDragging {
            resumePortionAnimation()
        }
    }
}

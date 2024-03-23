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
    typealias PortionId = Int
    
    @Published private(set) var barPortionAnimationStatusDict = [PortionId: BarPortionAnimationStatus]()
    @Published private(set) var currentPortionId: PortionId = -1
    
    private var subscriptions = Set<AnyCancellable>()
    
    let storyId: Int
    private let currentStoryAnimationHandler: CurrentStoryAnimationHandler
    
    init(storyId: Int, currentStoryAnimationHandler: CurrentStoryAnimationHandler) {
        self.storyId = storyId
        self.currentStoryAnimationHandler = currentStoryAnimationHandler
        
        if let firstPortionId = portions.first?.id {
            self.currentPortionId = firstPortionId
            self.initBarPortionAnimationStatus()
        }
        
        self.subscribePublishers()
    }
    
    deinit{
        print("\(String(describing: Self.self)): \(storyId) deinit.")
    }
}

extension StoryAnimationHandler {
    var currentStoryId: Int {
        currentStoryAnimationHandler.currentStoryId
    }
    
    var currentPortionAnimationStatus: BarPortionAnimationStatus? {
        barPortionAnimationStatusDict[currentPortionId]
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
    
    private var currentPortionIndex: Int? {
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
        guard isCurrentPortionAnimating else { return }
        
        setCurrentBarPortionAnimationStatus(to: .pause)
    }
    
    func resumePortionAnimation() {
        guard currentPortionAnimationStatus == .pause else { return }
        
        setCurrentBarPortionAnimationStatus(to: .resume)
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
        guard let currentPortionIndex else { return }
        
        let nextPortionIndex = currentPortionIndex+1
        if nextPortionIndex < portions.count {
            currentPortionId = portions[nextPortionIndex].id
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func resumePortionAnimationIfStayAtSameStoryAfterDragged() {
        if currentStoryAnimationHandler.isSameStoryAfterDragging {
            resumePortionAnimation()
        }
    }
}

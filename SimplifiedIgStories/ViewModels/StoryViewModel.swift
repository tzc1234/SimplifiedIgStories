//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import UIKit

final class StoryViewModel: ObservableObject {
    @Published var showConfirmationDialog = false
    @Published private(set) var noticeMsg = ""
    
    private let storyId: Int
    
    init(storyId: Int) {
        self.storyId = storyId
    }
    
    func showNotice(message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.noticeMsg = message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.noticeMsg = ""
            }
        }
    }
    
    deinit {
        print("StoryViewModel: \(storyId) deinit.")
    }
}

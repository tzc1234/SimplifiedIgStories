//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import UIKit

final class StoryViewModel: ObservableObject {
    @Published var showConfirmationDialog = false
    @Published private(set) var showNoticeLabel = false
    @Published private(set) var noticeMsg = ""
    
    private let storyId: Int
    private let fileManager: FileManageable
    
    init(storyId: Int, fileManager: FileManageable) {
        self.storyId = storyId
        self.fileManager = fileManager
    }
    
    func showNotice(message: String?) {
        guard let message else { return }
        
        noticeMsg = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showNoticeLabel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showNoticeLabel = false
            }
        }
    }
    
    deinit {
        print("StoryViewModel: \(storyId) deinit.")
    }
}

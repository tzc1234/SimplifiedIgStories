//
//  HomeUIActionHandler.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/07/2022.
//

import SwiftUI

final class HomeUIActionHandler: ObservableObject {
    @Published var showContainer = false
    @Published var showStoryCamView = false
    
    func showStoryContainer() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showContainer = true
        }
    }

    func toggleStoryCamView() {
        withAnimation(.default) {
            showStoryCamView.toggle()
        }
    }
    
    func closeStoryContainer() {
        // Don't use .spring(). If you switch the StoryContainer fast from one, close then open another,
        // there will be a weird behaviour. The StoryView can not be updated completely and broken.
        withAnimation(.easeInOut(duration: 0.3)) {
            showContainer = false
        }
    }
}

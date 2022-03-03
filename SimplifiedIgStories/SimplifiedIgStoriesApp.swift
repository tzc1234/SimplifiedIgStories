//
//  SimplifiedIgStoriesApp.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/2/2022.
//

import SwiftUI

@main
struct SimplifiedIgStoriesApp: App {
    @StateObject private var modelData = ModelData()
    
    var body: some Scene {
        WindowGroup {
//            HomeView().environmentObject(modelData)
//            VideoRecordButton()
            StoryCamView()
        }
    }
}

//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    @StateObject var globalObj = GlobalObject()
    
    var body: some View {
        NavigationView {
            VStack {
                StoryIconsView()
                Spacer()
            }
            .navigationTitle("IG Stories")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .environmentObject(globalObj)
        .onChange(of: globalObj.currentStoryIconIndex) { newValue in
            if newValue > -1 {
                print("StoryIcon frame: \(globalObj.currentStoryIconFrame)")
                globalObj.currentStoryIconIndex = -1
            }
        }
        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

struct StoryContainer: View {
    var body: some View {
        Color.red
    }
}

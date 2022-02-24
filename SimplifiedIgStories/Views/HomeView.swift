//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    static let coordinateSpaceName = "Home"
    
    @StateObject private var globalObject = GlobalObject()
    @State private var titleHeight = 44.0
    
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear.frame(height: geo.safeAreaInsets.top)
                        
                        Text("IG Stories")
                            .font(.title)
                            .bold()
                            .frame(height: titleHeight, alignment: .leading)
                            .padding(.horizontal, 16)
                        
                        StoryIconsView()
                        Spacer()
                    }
                    // In order to have a soomth animation, I don't use the navigationBar.
                    .navigationBarHidden(true)

                    if globalObject.showContainer {
                        let topSpacing = geo.safeAreaInsets.top == 0 ? 0 : titleHeight / 2 + geo.safeAreaInsets.top / 2
                        let offset = CGSize(
                            width: -(geo.size.width / 2 - globalObject.currentStoryIconFrame.midX + StoryIconsView.spacing / 2),
                            height: -(geo.size.height / 2 - globalObject.currentStoryIconFrame.midY + topSpacing)
                        )
                        StoryContainer(topSpacing: geo.safeAreaInsets.top)
                            .zIndex(1)
                            .transition(.iOSNativeOpenAppTransition(offest: offset))
                    }
                }
                .coordinateSpace(name: Self.coordinateSpaceName)
                .ignoresSafeArea()
                
            }
            .environmentObject(globalObject)
        }
        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(ModelData())
    }
}

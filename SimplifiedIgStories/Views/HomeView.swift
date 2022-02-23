//
//  HomeView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct HomeView: View {
    static let coordinateSpaceName = "Home"
    
    @StateObject var globalObject = GlobalObject()
    @EnvironmentObject var modelData: ModelData
    @State private var titleHeight = 44.0
    
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                ZStack {
                    if globalObject.showContainer {
                        let spacing = geo.safeAreaInsets.top == 0 ? 0 : titleHeight / 2 + geo.safeAreaInsets.top / 2
                        StoryContainer(story: modelData.stories[globalObject.currentStoryIconIndex], topSpacing: geo.safeAreaInsets.top)
                            .zIndex(1.0)
                            .transition(
                                AnyTransition.scale(scale: 0.08)
                                    .combined(
                                        with:
                                            AnyTransition.offset(
                                                x: -(geo.size.width / 2 - globalObject.currentStoryIconFrame.midX + StoryIconsView.spacing / 2),
                                                y: -(geo.size.height / 2 - globalObject.currentStoryIconFrame.midY + spacing)
                                            )
                                    )
                            )
                    }
                    
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
                    .navigationBarHidden(true)
                }
                .coordinateSpace(name: Self.coordinateSpaceName)
                .ignoresSafeArea()
                
            }
            .environmentObject(globalObject)
//            .onChange(of: globalObject.currentStoryIconIndex) { newValue in
//                if newValue > -1 {
//                    withAnimation(.spring()) {
//                        showContainer.toggle()
//                    }
//                }
//                globalObject.currentStoryIconIndex = -1
//            }
            
        }
        
    }
}

struct HomeView_Previews: PreviewProvider {
    @StateObject static var modelData = ModelData()
    static var previews: some View {
        HomeView().environmentObject(modelData)
    }
}

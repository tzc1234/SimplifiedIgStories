//
//  StoryContainer.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryContainer: View {
    @EnvironmentObject private var vm: StoryViewModel
    @GestureState private var translation: CGFloat = 0
    
    private let width = UIScreen.main.bounds.width
    private let height = UIScreen.main.bounds.height
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // *** A risk of memory leak if too many stories.
            ForEach(vm.atLeastOnePortionStories) { story in
                GeometryReader { geo in
                    let frame = geo.frame(in: .global)
                    StoryView(story: story)
                    // Cubic transition reference: https://www.youtube.com/watch?v=NTun83toSQQ&ab_channel=Kavsoft
                        .rotation3DEffect(
                            vm.shouldAnimateCubicRotation ? .degrees(getRotationDegree(offsetX: frame.minX)) : .degrees(0),
                            axis: (x: 0.0, y: 1.0, z: 0.0),
                            anchor: frame.minX > 0 ? .leading : .trailing,
                            anchorZ: 0.0,
                            perspective: 2.5
                        )
                }
                .frame(width: width, height: height)
                .ignoresSafeArea()
                .opacity(story.id != vm.currentStoryId && !vm.shouldAnimateCubicRotation ? 0.0 : 1.0)
            }
        }
        .frame(width: width, alignment: .leading)
        .offset(x: vm.getContainerOffset(width: width))
        .offset(x: translation)
        .animation(.interactiveSpring(), value: vm.currentStoryId)
        .animation(.interactiveSpring(), value: translation)
        .gesture(
            DragGesture()
                .updating($translation) { value, state, transaction in
                    vm.dragStoryContainer()
                    state = value.translation.width
                }
                .onEnded { value in
                    vm.endDraggingStoryContainer(offset: value.translation.width / width)
                }
        )
        .statusBar(hidden: true)
    }
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        let vm = StoryViewModel(dataService: MockDataService())
        StoryContainer().environmentObject(vm)
    }
}

// MARK: functions
extension StoryContainer {
    private func getRotationDegree(offsetX: CGFloat) -> Double {
        let tempAngle = offsetX / (width / 2)
        let rotationDegree = 20.0
        return tempAngle * rotationDegree
    }
}

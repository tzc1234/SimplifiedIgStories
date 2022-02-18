//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryView: View {
    var body: some View {
        ZStack {
            StoryPhotoView()

            DetectableTapGesturePositionView { point in
                print("x: \(point.x), y: \(point.y)")
            }
            .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                ProgressBar()
                    .frame(height: 3, alignment: .center)

                HStack {
                    avatarIcon
                    nameText
                    dateText
                    Spacer()
                    closeButton
                }.padding(.horizontal, 18)

                Spacer()
            }
        }
    }
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView()
    }
}

// MARK: components
extension StoryView {
    var avatarIcon: some View {
        Image("avatar")
            .resizable()
            .frame(width: 45, height: 45)
            .overlay(Circle().strokeBorder(.white, lineWidth: 1))
    }
    
    var nameText: some View {
        Text("Person0")
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    var dateText: some View {
        Text("15h")
            .foregroundColor(.white)
            .font(.subheadline)
    }
    
    var closeButton: some View {
        Button {
            print("Close tapped.")
        } label: {
            Image(systemName: "xmark")
                .resizable()
                .foregroundColor(.white)
                .frame(width: 35, height: 35)
        }
    }
}

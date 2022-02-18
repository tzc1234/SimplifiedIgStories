//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryView: View {
    
    private let avatarSize = 45.0
    
    var body: some View {
        ZStack {
            StoryPhotoView()
            
            VStack(alignment: .leading) {
                ProgressBar()
                    .frame(height: 3, alignment: .center)
                
                GeometryReader { geo in
                    HStack {
                        Image("avatar")
                            .resizable()
                            .frame(width: avatarSize, height: avatarSize)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 1))
                        
                        Text("Person0")
                            .foregroundColor(.white)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            
                        Text("15h")
                            .foregroundColor(.white)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button {
                            print("Tapped!")
                        } label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 35, height: 35)
                        }

                        
                    }.padding(.horizontal, 18)
                }
                
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

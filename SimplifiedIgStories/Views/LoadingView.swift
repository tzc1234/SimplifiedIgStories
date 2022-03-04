//
//  LoadingView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.clear
            
            ProgressView()
                .progressViewStyle(.circular)
                .preferredColorScheme(.dark)
                .scaleEffect(2)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.darkGray)
                        .frame(width: 90, height: 90)
                )
        }
        .ignoresSafeArea()
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}

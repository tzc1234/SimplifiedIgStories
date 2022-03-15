//
//  NoticeLabel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 14/03/2022.
//

import SwiftUI

struct NoticeLabel: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.darkGray)
            )
            .padding()
    }
}

struct SavedLabel_Previews: PreviewProvider {
    static var previews: some View {
        NoticeLabel(message: "Saved.")
    }
}

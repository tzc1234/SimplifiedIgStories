//
//  SavedLabel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 14/03/2022.
//

import SwiftUI

struct SavedLabel: View {
    var body: some View {
        Text("Saved")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.darkGray)
            )
    }
}

struct SavedLabel_Previews: PreviewProvider {
    static var previews: some View {
        SavedLabel()
    }
}

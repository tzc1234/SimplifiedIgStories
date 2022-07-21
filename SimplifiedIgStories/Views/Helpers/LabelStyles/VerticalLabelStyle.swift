//
//  VerticalLabelStyle.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 11/03/2022.
//

import SwiftUI

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 6.0) {
            configuration.icon.frame(width: 35, height: 35)
            configuration.title
        }
    }
}

extension LabelStyle where Self == VerticalLabelStyle {
    static var verticalLabelStyle: VerticalLabelStyle {
        VerticalLabelStyle()
    }
}

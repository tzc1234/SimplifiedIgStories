//
//  PermissionView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 14/03/2022.
//

import SwiftUI

struct PermissionView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 4.0) {
            Spacer()
            Spacer()
            Spacer()
            
            Text("Share Your Story")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                
            Text("Enable access to take photos and record videos.")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                gotoSettings()
            } label: {
                Text("Enable Camera Access")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()
            Spacer()
            Spacer()
        }
        .padding()
        .background(
            Rectangle().fill(.background)
        )
        
    }
}

struct PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionView()
            .preferredColorScheme(.dark)
    }
}

// MARK: functions
extension PermissionView {
    private func gotoSettings() {
        guard
            let url = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(url)
        else {
            return
        }
        
        UIApplication.shared.open(url) { isSuccess in
            if isSuccess {
                print("Goto settings success.")
            }
        }
    }
}

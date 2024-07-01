//
//  StoryCamPermissionView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 14/03/2022.
//

import SwiftUI
import Combine

struct StoryCamPermissionView: View {
    @ObservedObject private var vm: StoryCameraViewModel
    
    init(storyCamViewModel: StoryCameraViewModel) {
        self.vm = storyCamViewModel
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4.0) {
            Group {
                Spacer()
                Spacer()
                Spacer()
            }
            
            Text("Share Your Story")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                
            Text("Enable access to take photos and record videos.")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(alignment: .center, spacing: 22.0) {
                Button {
                    gotoSettings()
                } label: {
                    Text(vm.isCamPermGranted ? "✓ Camera access enabled" : "Enable Camera Access")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .disabled(vm.isCamPermGranted)
                
                Button {
                    gotoSettings()
                } label: {
                    Text(vm.isMicrophonePermGranted ? "✓ Microphone access enabled" : "Enable Microphone Access")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .disabled(vm.isMicrophonePermGranted)
            }

            Group {
                Spacer()
                Spacer()
                Spacer()
            }
        }
        .padding()
        .background(
            Rectangle().fill(.background)
        )
        
    }
    
    private func gotoSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        
        UIApplication.shared.open(url) { isSuccess in
            if isSuccess {
                print("Goto settings success.")
            }
        }
    }
}

struct PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        StoryCamPermissionView(storyCamViewModel: StoryCameraViewModel(camera: DefaultCamera.dummy))
    }
}

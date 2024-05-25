//Made by Lumaa

import SwiftUI
import AVKit

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        
        // Indicate whether your app prefers video content.
        routePickerView.prioritizesVideoDevices = false
                
        return routePickerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

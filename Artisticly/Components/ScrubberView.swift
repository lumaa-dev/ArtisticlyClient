//Made by Lumaa

import SwiftUI

struct ScrubberView: View {
    
    @Binding var value: Double
    
    var minValue: Float = 0.0
    var maxValue: Float = 100.0
    
    @State private var executedEdit: Bool = false
    var onEdit: ((Bool) -> Void) = {_ in }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Material.thin)
                
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: geometry.size.width * CGFloat(self.value / Double(maxValue)))
            }
            .cornerRadius(12)
            .gesture(DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    onEdit(false)
                }
                .onChanged({ value in
                    self.value = Double(min(max(minValue, Float(value.location.x / geometry.size.width) * maxValue), 100))
                    
                    if !executedEdit {
                        onEdit(true)
                        executedEdit = true
                    }
                }))
        }
        .frame(height: 10)
    }
}

#Preview {
    ZStack {
        Color.gray
        
        ScrubberView(value: .constant(35.0))
            .padding(.horizontal)
    }
}

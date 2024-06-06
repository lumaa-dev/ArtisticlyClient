//Made by Lumaa

import SwiftUI

struct ScrubberView: View {
    
    @Binding var value: Double
    @State private var holding: Bool = false
    
    @State private var isDisabled: Bool = false
    
    var minValue: Float = 0.0
    var maxValue: Float = 100.0
    
    @State private var executedEdit: Bool = false
    var onEdit: ((Bool) -> Void) = {_ in }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(holding ? Material.regular : Material.thin)
                    .frame(height: holding ? 13.5 : 10, alignment: .center)
                
                if !isDisabled {
                    Rectangle()
                        .fill(Color.white.opacity(holding ? 0.85 : 0.6))
                        .frame(width: geometry.size.width * CGFloat(self.value / Double(maxValue)), height: holding ? 13.5 : 10, alignment: .center)
                }
            }
            .cornerRadius(12)
            .gesture(DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    guard !isDisabled else { return }
                    
                    onEdit(false)
                    executedEdit = false
                    
                    withAnimation(.spring) {
                        self.holding = false
                    }
                }
                .onChanged({ value in
                    guard !isDisabled else { return }
                    
                    self.value = Double(min(max(minValue, Float(value.location.x / geometry.size.width) * maxValue), 100))
                    
                    withAnimation(.spring) {
                        self.holding = true
                    }
                    
                    if !executedEdit {
                        onEdit(true)
                        executedEdit = true
                    }
                }))
        }
        .frame(height: 30, alignment: .center)
    }
    
    func disabled(_ state: Bool) -> some View {
        self.isDisabled = state
        return self
    }
}

#Preview {
    ZStack {
        Color.gray
        
        ScrubberView(value: .constant(35.0))
            .padding(.horizontal)
    }
}

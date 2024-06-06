//Made by Lumaa

import SwiftUI

struct FullSheetStyle: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        return .init()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let rootView = uiView.viewBeforeWindow {
                rootView.frame = .init(
                    origin: CGPoint.zero,
                    size: .init(width: rootView.frame.width, height: rootView.frame.height)
                )
                
                rootView.bounds.size = .init(width: rootView.bounds.width, height: rootView.bounds.height + 140) // 140 is constant
            }
        }
    }
}

struct NoTapAnimationStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onTapGesture(perform: configuration.trigger)
    }
}

extension View {
    @ViewBuilder
    func fullSheet(_ dragIndicator: Visibility) -> some View {
        self
            .background(FullSheetStyle())
            .presentationDragIndicator(dragIndicator)
            .presentationDetents([.large])
            .presentationCornerRadius(25.0)
    }
    
    @ViewBuilder
    func showGrabber() -> some View {
        self
            .overlay(alignment: .top) {
                Capsule(style: .circular)
                    .frame(width: 35, height: 5, alignment: .center)
                    .safeAreaPadding()
                    .offset(y: -10.0)
                    .foregroundStyle(Color.white.opacity(0.9))
            }
    }
}

fileprivate extension UIView {
    var viewBeforeWindow: UIView? {
        if let superview, superview is UIWindow {
            return self
        }
        
        return superview?.viewBeforeWindow
    }
}

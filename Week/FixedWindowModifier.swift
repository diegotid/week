import SwiftUI

struct FixedWindowModifier: ViewModifier {
    let size: CGSize

    func body(content: Content) -> some View {
        content
            .background(WindowAccessor(size: size))
    }

    private struct WindowAccessor: NSViewRepresentable {
        let size: CGSize
        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                if let window = view.window {
                    window.styleMask.remove(.resizable)
                    window.setContentSize(size)
                    window.minSize = size
                    window.maxSize = size
                }
            }
            return view
        }
        func updateNSView(_ nsView: NSView, context: Context) {
            DispatchQueue.main.async {
                if let window = nsView.window {
                    window.styleMask.remove(.resizable)
                    window.setContentSize(size)
                    window.minSize = size
                    window.maxSize = size
                }
            }
        }
    }
}

extension View {
    func fixedWindow(size: CGSize) -> some View {
        self.modifier(FixedWindowModifier(size: size))
    }
}

import SwiftUI
import UIKit

struct KeyboardAccessoryBarRepresentable: UIViewRepresentable {
    var onKeyData: (Data) -> Void
    var onDismissKeyboard: () -> Void
    var onShowKeyboard: () -> Void

    func makeUIView(context: Context) -> KeyboardAccessoryView {
        let view = KeyboardAccessoryView(frame: .zero)
        view.onKeyInput = onKeyData
        view.onDismissKeyboard = onDismissKeyboard
        view.onShowKeyboard = onShowKeyboard
        return view
    }

    func updateUIView(_ uiView: KeyboardAccessoryView, context: Context) {
        uiView.onKeyInput = onKeyData
        uiView.onDismissKeyboard = onDismissKeyboard
        uiView.onShowKeyboard = onShowKeyboard
    }
}

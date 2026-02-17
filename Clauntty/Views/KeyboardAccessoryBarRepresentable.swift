import SwiftUI
import UIKit

struct KeyboardAccessoryBarRepresentable: UIViewRepresentable {
    var onKeyData: (Data) -> Void
    var onDismissKeyboard: () -> Void
    var onShowKeyboard: () -> Void
    var onMoveLineUp: () -> Void
    var onMoveLineDown: () -> Void
    var onIndentLine: () -> Void
    var onUnindentLine: () -> Void
    var onCyclePrefix: () -> Void
    var nippleControlsLineOps: Bool

    func makeUIView(context: Context) -> KeyboardAccessoryView {
        let view = KeyboardAccessoryView(frame: .zero)
        view.onKeyInput = onKeyData
        view.onDismissKeyboard = onDismissKeyboard
        view.onShowKeyboard = onShowKeyboard
        view.onMoveLineUp = onMoveLineUp
        view.onMoveLineDown = onMoveLineDown
        view.onIndentLine = onIndentLine
        view.onUnindentLine = onUnindentLine
        view.onCyclePrefix = onCyclePrefix
        view.nippleControlsLineOps = nippleControlsLineOps
        return view
    }

    func updateUIView(_ uiView: KeyboardAccessoryView, context: Context) {
        uiView.onKeyInput = onKeyData
        uiView.onDismissKeyboard = onDismissKeyboard
        uiView.onShowKeyboard = onShowKeyboard
        uiView.onMoveLineUp = onMoveLineUp
        uiView.onMoveLineDown = onMoveLineDown
        uiView.onIndentLine = onIndentLine
        uiView.onUnindentLine = onUnindentLine
        uiView.onCyclePrefix = onCyclePrefix
        uiView.nippleControlsLineOps = nippleControlsLineOps
    }
}

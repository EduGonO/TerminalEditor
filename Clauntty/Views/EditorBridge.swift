import UIKit
import SwiftUI

@MainActor
final class EditorBridge: ObservableObject {
    weak var activeTextView: UITextView?

    func dismissKeyboard() {
        activeTextView?.resignFirstResponder()
    }

    func showKeyboard() {
        activeTextView?.becomeFirstResponder()
    }

    func insert(_ string: String) {
        guard let textView = activeTextView, let selectedRange = textView.selectedTextRange else { return }
        textView.replace(selectedRange, withText: string)
        textView.delegate?.textViewDidChange?(textView)
    }

    func moveCursor(horizontal: Int) {
        guard let textView = activeTextView else { return }
        let selected = textView.selectedRange
        let newLocation = max(0, min((textView.text as NSString).length, selected.location + horizontal))
        textView.selectedRange = NSRange(location: newLocation, length: 0)
    }

    func moveCursor(vertical: Int) {
        guard let textView = activeTextView else { return }
        let selected = textView.selectedRange
        guard let position = textView.position(from: textView.beginningOfDocument, offset: selected.location) else { return }

        let rect = textView.caretRect(for: position)
        let lineHeight = textView.font?.lineHeight ?? 18
        let target = CGPoint(x: rect.midX, y: rect.midY + (CGFloat(vertical) * lineHeight))

        if let newPosition = textView.closestPosition(to: target) {
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
        }
    }

    func undo() {
        activeTextView?.undoManager?.undo()
    }

    func redo() {
        activeTextView?.undoManager?.redo()
    }

    func handleKeyData(_ data: Data) {
        switch Array(data) {
        case [0x1B, 0x5B, 0x41]: moveCursor(vertical: -1)  // ESC[A
        case [0x1B, 0x5B, 0x42]: moveCursor(vertical: 1)   // ESC[B
        case [0x1B, 0x5B, 0x43]: moveCursor(horizontal: 1) // ESC[C
        case [0x1B, 0x5B, 0x44]: moveCursor(horizontal: -1) // ESC[D
        case [0x1B]: insert("\u{1B}")
        case [0x09]: insert("\t")
        case [0x0D]: insert("\n")
        case [0x03]: insert("^C")
        case [0x0F]: insert("^O")
        case [0x02]: insert("^B")
        default:
            if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                insert(text)
            }
        }
    }
}

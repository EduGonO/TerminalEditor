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

    func moveCurrentLineUp() {
        moveCurrentLine(offset: -1)
    }

    func moveCurrentLineDown() {
        moveCurrentLine(offset: 1)
    }

    func indentCurrentLine() {
        transformCurrentLines { "    " + $0 }
    }

    func unindentCurrentLine() {
        transformCurrentLines { line in
            if line.hasPrefix("    ") { return String(line.dropFirst(4)) }
            if line.hasPrefix("\t") { return String(line.dropFirst()) }
            return line
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
        default:
            if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                insert(text)
            }
        }
    }

    private func moveCurrentLine(offset: Int) {
        guard let textView = activeTextView else { return }
        let text = textView.text ?? ""
        let ns = text as NSString
        let selected = textView.selectedRange
        let lineRange = ns.lineRange(for: selected)

        let lines = text.components(separatedBy: "\n")
        let currentLineIndex = lineIndex(containingUTF16Location: selected.location, in: text)
        let targetIndex = currentLineIndex + offset
        guard targetIndex >= 0, targetIndex < lines.count else { return }

        var mutableLines = lines
        mutableLines.swapAt(currentLineIndex, targetIndex)
        let newText = mutableLines.joined(separator: "\n")

        textView.text = newText
        let newCaret = lineStartUTF16Offset(for: targetIndex, in: mutableLines)
        textView.selectedRange = NSRange(location: min(newCaret, (newText as NSString).length), length: 0)
        textView.delegate?.textViewDidChange?(textView)

        // keep compiler aware we intentionally derived line range for selected block semantics
        _ = lineRange
    }

    private func transformCurrentLines(_ transform: (String) -> String) {
        guard let textView = activeTextView else { return }
        let text = textView.text ?? ""
        let lines = text.components(separatedBy: "\n")
        let selected = textView.selectedRange

        let startLine = lineIndex(containingUTF16Location: selected.location, in: text)
        let endLocation = max(selected.location, selected.location + max(0, selected.length - 1))
        let endLine = lineIndex(containingUTF16Location: endLocation, in: text)

        guard !lines.isEmpty else { return }

        var mutableLines = lines
        for i in startLine...min(endLine, mutableLines.count - 1) {
            mutableLines[i] = transform(mutableLines[i])
        }

        let newText = mutableLines.joined(separator: "\n")
        textView.text = newText
        textView.selectedRange = selected
        textView.delegate?.textViewDidChange?(textView)
    }

    private func lineIndex(containingUTF16Location location: Int, in text: String) -> Int {
        let lines = text.components(separatedBy: "\n")
        var running = 0
        for (idx, line) in lines.enumerated() {
            let len = (line as NSString).length
            if location <= running + len { return idx }
            running += len + 1
        }
        return max(0, lines.count - 1)
    }

    private func lineStartUTF16Offset(for index: Int, in lines: [String]) -> Int {
        guard index > 0 else { return 0 }
        return lines.prefix(index).reduce(0) { $0 + ($1 as NSString).length + 1 }
    }
}

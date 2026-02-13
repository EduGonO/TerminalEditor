import UIKit
import SwiftUI

enum EditorFontStyle: String, CaseIterable {
    case mono
    case sans
    case serif

    var label: String {
        switch self {
        case .mono: return "Mono"
        case .sans: return "Sans"
        case .serif: return "Serif"
        }
    }

    func font(size: CGFloat) -> UIFont {
        switch self {
        case .mono:
            return .monospacedSystemFont(ofSize: size, weight: .regular)
        case .sans:
            return .systemFont(ofSize: size, weight: .regular)
        case .serif:
            return .systemFont(ofSize: size, weight: .regular, design: .serif)
                ?? .systemFont(ofSize: size, weight: .regular)
        }
    }
}

@MainActor
final class EditorBridge: ObservableObject {
    weak var activeTextView: UITextView?

    @Published private(set) var fontStyle: EditorFontStyle = .mono
    @Published private(set) var fontSize: CGFloat = 15
    @Published private(set) var nippleControlsLineOps = false

    private let minFontSize: CGFloat = 11
    private let maxFontSize: CGFloat = 28

    func dismissKeyboard() {
        activeTextView?.resignFirstResponder()
    }

    func showKeyboard() {
        activeTextView?.becomeFirstResponder()
    }

    func cycleFontStyle() {
        let all = EditorFontStyle.allCases
        guard let idx = all.firstIndex(of: fontStyle) else { return }
        fontStyle = all[(idx + 1) % all.count]
    }

    func setFontStyle(_ style: EditorFontStyle) {
        fontStyle = style
    }

    func increaseFontSize() {
        fontSize = min(maxFontSize, fontSize + 1)
    }

    func decreaseFontSize() {
        fontSize = max(minFontSize, fontSize - 1)
    }

    func editorFont() -> UIFont {
        fontStyle.font(size: fontSize)
    }

    func toggleNippleMode() {
        nippleControlsLineOps.toggle()
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func moveCurrentLineUp() {
        moveCurrentLine(offset: -1)
    }

    func moveCurrentLineDown() {
        moveCurrentLine(offset: 1)
    }

    func indentCurrentLine() {
        transformCurrentLines { line in
            ("    " + line, 4)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func unindentCurrentLine() {
        transformCurrentLines { line in
            if line.hasPrefix("    ") {
                return (String(line.dropFirst(4)), -4)
            }
            if line.hasPrefix("	") {
                return (String(line.dropFirst()), -1)
            }
            return (line, 0)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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

        let lines = text.components(separatedBy: "\n")
        let currentLineIndex = lineIndex(containingUTF16Location: textView.selectedRange.location, in: text)
        let targetIndex = currentLineIndex + offset
        guard targetIndex >= 0, targetIndex < lines.count else { return }

        let originalSelection = textView.selectedRange
        let currentLineStart = lineStartUTF16Offset(for: currentLineIndex, in: lines)
        let targetLineStart = lineStartUTF16Offset(for: targetIndex, in: lines)

        var mutableLines = lines
        mutableLines.swapAt(currentLineIndex, targetIndex)
        let newText = mutableLines.joined(separator: "\n")

        let remappedStart = remapLocationForSwappedLines(
            originalSelection.location,
            currentLineIndex: currentLineIndex,
            targetLineIndex: targetIndex,
            currentLineStart: currentLineStart,
            targetLineStart: targetLineStart,
            originalLines: lines,
            swappedLines: mutableLines
        )
        let remappedEndExclusive = remapLocationForSwappedLines(
            originalSelection.location + originalSelection.length,
            currentLineIndex: currentLineIndex,
            targetLineIndex: targetIndex,
            currentLineStart: currentLineStart,
            targetLineStart: targetLineStart,
            originalLines: lines,
            swappedLines: mutableLines
        )

        textView.text = newText
        let clampedStart = max(0, min(remappedStart, (newText as NSString).length))
        let clampedEnd = max(clampedStart, min(remappedEndExclusive, (newText as NSString).length))
        textView.selectedRange = NSRange(location: clampedStart, length: clampedEnd - clampedStart)
        textView.delegate?.textViewDidChange?(textView)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func transformCurrentLines(_ transform: (String) -> (line: String, leadingDelta: Int)) {
        guard let textView = activeTextView else { return }
        let text = textView.text ?? ""
        let lines = text.components(separatedBy: "\n")
        guard !lines.isEmpty else { return }

        let selected = textView.selectedRange
        let endLocation = max(selected.location, selected.location + max(0, selected.length - 1))

        let startLine = lineIndex(containingUTF16Location: selected.location, in: text)
        let endLine = lineIndex(containingUTF16Location: endLocation, in: text)

        var mutableLines = lines
        var leadingDeltas: [Int: Int] = [:]

        for i in startLine...min(endLine, mutableLines.count - 1) {
            let result = transform(mutableLines[i])
            mutableLines[i] = result.line
            leadingDeltas[i] = result.leadingDelta
        }

        let newText = mutableLines.joined(separator: "\n")

        let newStart = adjustedLocation(
            selected.location,
            lineDeltas: leadingDeltas,
            originalLines: lines
        )
        let newEndExclusive = adjustedLocation(
            selected.location + selected.length,
            lineDeltas: leadingDeltas,
            originalLines: lines
        )

        textView.text = newText
        let clampedStart = max(0, min(newStart, (newText as NSString).length))
        let clampedEnd = max(clampedStart, min(newEndExclusive, (newText as NSString).length))
        textView.selectedRange = NSRange(location: clampedStart, length: clampedEnd - clampedStart)
        textView.delegate?.textViewDidChange?(textView)
    }


    private func remapLocationForSwappedLines(
        _ location: Int,
        currentLineIndex: Int,
        targetLineIndex: Int,
        currentLineStart: Int,
        targetLineStart: Int,
        originalLines: [String],
        swappedLines: [String]
    ) -> Int {
        let currentLineLength = (originalLines[currentLineIndex] as NSString).length
        let targetLineLength = (originalLines[targetLineIndex] as NSString).length

        if location >= currentLineStart && location <= currentLineStart + currentLineLength {
            let column = location - currentLineStart
            let newStart = lineStartUTF16Offset(for: targetLineIndex, in: swappedLines)
            let maxColumn = (swappedLines[targetLineIndex] as NSString).length
            return newStart + min(column, maxColumn)
        }

        if location >= targetLineStart && location <= targetLineStart + targetLineLength {
            let column = location - targetLineStart
            let newStart = lineStartUTF16Offset(for: currentLineIndex, in: swappedLines)
            let maxColumn = (swappedLines[currentLineIndex] as NSString).length
            return newStart + min(column, maxColumn)
        }

        return location
    }

    private func adjustedLocation(_ location: Int, lineDeltas: [Int: Int], originalLines: [String]) -> Int {
        var running = 0
        for (lineIndex, line) in originalLines.enumerated() {
            let lineLength = (line as NSString).length
            let lineStart = running
            let lineEndExclusive = running + lineLength

            if location <= lineEndExclusive {
                guard let delta = lineDeltas[lineIndex], delta != 0 else { return location }
                let column = location - lineStart

                if delta > 0 {
                    return location + delta
                }

                let removed = abs(delta)
                return column <= removed ? lineStart : location - removed
            }

            running += lineLength + 1
        }

        return location
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

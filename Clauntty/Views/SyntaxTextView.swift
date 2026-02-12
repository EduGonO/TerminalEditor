import SwiftUI
import UIKit

struct SyntaxTextView: UIViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    @ObservedObject var bridge: EditorBridge

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.backgroundColor = .clear
        textView.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.text = text
        applyHighlighting(to: textView)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            applyHighlighting(to: uiView)
        }

        if isFocused {
            bridge.activeTextView = uiView
            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: SyntaxTextView
        init(_ parent: SyntaxTextView) { self.parent = parent }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.bridge.activeTextView = textView
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.applyHighlighting(to: textView)
        }
    }

    private func applyHighlighting(to textView: UITextView) {
        let full = textView.text ?? ""
        let attr = NSMutableAttributedString(string: full)
        let baseRange = NSRange(location: 0, length: attr.length)

        attr.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 15, weight: .regular), range: baseRange)
        attr.addAttribute(.foregroundColor, value: UIColor.label, range: baseRange)

        color(pattern: "\\b(func|let|var|if|else|return|struct|class|import|enum|protocol|extension)\\b", in: full, attr: attr, color: .systemBlue)
        color(pattern: "\"(\\\\.|[^\"\\\\])*\"", in: full, attr: attr, color: .systemGreen)
        color(pattern: "//.*", in: full, attr: attr, color: .systemGray)

        let selected = textView.selectedRange
        textView.attributedText = attr
        textView.selectedRange = selected
    }

    private func color(pattern: String, in text: String, attr: NSMutableAttributedString, color: UIColor) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        let range = NSRange(location: 0, length: (text as NSString).length)
        regex.matches(in: text, options: [], range: range).forEach { match in
            attr.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }
}

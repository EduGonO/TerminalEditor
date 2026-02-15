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
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.text = text
        applyHighlighting(to: textView)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        applyHighlighting(to: uiView)

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
        let fullRange = NSRange(location: 0, length: (full as NSString).length)
        let attr = NSMutableAttributedString(string: full)
        let selected = textView.selectedRange

        let editorFont = bridge.editorFont()
        let monoFont = UIFont.monospacedSystemFont(ofSize: editorFont.pointSize, weight: .regular)
        let smallMono = UIFont.monospacedSystemFont(ofSize: max(11, editorFont.pointSize - 1), weight: .regular)

        attr.addAttribute(.font, value: editorFont, range: fullRange)
        attr.addAttribute(.foregroundColor, value: Palette.baseText, range: fullRange)

        applyRegex(Regex.heading, in: full) { match in
            let markerRange = match.range(at: 1)
            let textRange = match.range(at: 3)
            guard markerRange.location != NSNotFound, textRange.location != NSNotFound else { return }

            attr.addAttributes([.font: smallMono, .foregroundColor: Palette.marker], range: markerRange)

            let level = max(1, min(6, (full as NSString).substring(with: markerRange).count))
            let size = max(editorFont.pointSize + CGFloat(8 - level), editorFont.pointSize)
            attr.addAttributes([.font: UIFont.systemFont(ofSize: size, weight: .bold)], range: textRange)
        }

        applyRegex(Regex.doneLine, in: full) { match in
            attr.addAttributes([
                .foregroundColor: Palette.comment,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue
            ], range: match.range)
        }

        applyRegex(Regex.doneTaskLine, in: full) { match in
            attr.addAttributes([
                .font: monoFont,
                .foregroundColor: Palette.comment,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue
            ], range: match.range)
        }

        applyRegex(Regex.commentLine, in: full) { match in
            attr.addAttribute(.foregroundColor, value: Palette.comment, range: match.range)
        }

        applyRegex(Regex.doubleQuote, in: full) { match in
            attr.addAttributes([.foregroundColor: Palette.marker, .font: smallMono], range: match.range)
        }
        applyRegex(Regex.parenContent, in: full) { match in
            attr.addAttributes([.foregroundColor: Palette.marker, .font: smallMono], range: match.range)
        }
        applyRegex(Regex.bracketContent, in: full) { match in
            attr.addAttributes([.foregroundColor: Palette.marker, .font: smallMono], range: match.range)
        }
        applyRegex(Regex.guillemetContent, in: full) { match in
            attr.addAttributes([.foregroundColor: Palette.marker, .font: smallMono], range: match.range)
        }

        applyRegex(Regex.delTag, in: full) { match in
            attr.addAttributes([.foregroundColor: Palette.marker, .font: smallMono], range: match.range)
        }

        applyGroupColor(Regex.bulletMarkerRed, group: 1, in: full, attr: attr, color: Palette.red, font: monoFont)
        applyGroupColor(Regex.bulletMarkerGray, group: 1, in: full, attr: attr, color: Palette.marker, font: monoFont)
        applyGroupColor(Regex.numberMarker, group: 1, in: full, attr: attr, color: Palette.red, font: monoFont)
        applyGroupColor(Regex.todoMarker, group: 1, in: full, attr: attr, color: Palette.red, font: monoFont)

        applyRegex(Regex.taskLineAny, in: full) { match in
            attr.addAttribute(.font, value: monoFont, range: match.range)
        }
        applyGroupColor(Regex.taskOpen, group: 1, in: full, attr: attr, color: Palette.marker, font: monoFont)
        applyGroupColor(Regex.taskOpen, group: 2, in: full, attr: attr, color: Palette.red, font: monoFont)
        applyGroupColor(Regex.taskOpen, group: 3, in: full, attr: attr, color: Palette.red, font: monoFont)
        applyGroupColor(Regex.taskWarn, group: 1, in: full, attr: attr, color: Palette.marker, font: monoFont)
        applyGroupColor(Regex.taskWarn, group: 2, in: full, attr: attr, color: Palette.red, font: monoFont)
        applyGroupColor(Regex.taskWarn, group: 3, in: full, attr: attr, color: Palette.marker, font: monoFont)
        applyGroupColor(Regex.taskWarn, group: 4, in: full, attr: attr, color: Palette.red, font: monoFont)

        applyRegex(Regex.squareList, in: full) { match in
            let prefixRange = match.range(at: 1)
            let textRange = match.range(at: 2)
            if prefixRange.location != NSNotFound {
                attr.addAttributes([.foregroundColor: Palette.pink, .font: monoFont], range: prefixRange)
            }
            if textRange.location != NSNotFound {
                attr.addAttributes([
                    .foregroundColor: Palette.mention,
                    .font: UIFont.boldSystemFont(ofSize: editorFont.pointSize)
                ], range: textRange)
            }
        }

        applyGroupTrait(Regex.italic, group: 1, in: full, attr: attr, trait: .traitItalic)
        applyGroupTrait(Regex.bold, group: 1, in: full, attr: attr, trait: .traitBold)
        applyGroupStyle(Regex.underlineUnderscore, group: 1, in: full, attr: attr, attrs: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        applyGroupStyle(Regex.underlineTilde, group: 1, in: full, attr: attr, attrs: [.underlineStyle: NSUnderlineStyle.single.rawValue])

        applyRegex(Regex.highlightColon, in: full) { match in
            attr.addAttribute(.backgroundColor, value: Palette.highlight, range: match.range)
        }
        applyRegex(Regex.highlightEquals, in: full) { match in
            attr.addAttribute(.backgroundColor, value: Palette.highlight, range: match.range)
        }

        applyRegex(Regex.syntaxMarkers, in: full) { match in
            attr.addAttributes([.foregroundColor: Palette.marker, .font: smallMono], range: match.range)
        }

        applyRegex(Regex.wikiLink, in: full) { match in
            let total = match.range(at: 0)
            let inner = match.range(at: 1)
            attr.addAttributes([.foregroundColor: Palette.marker, .font: smallMono], range: total)
            if inner.location != NSNotFound {
                attr.addAttributes([.foregroundColor: Palette.pink, .font: editorFont], range: inner)
            }
        }

        applyRegex(Regex.markdownLink, in: full) { match in
            let total = match.range(at: 0)
            let label = match.range(at: 1)
            let target = match.range(at: 2)
            attr.addAttributes([.foregroundColor: Palette.marker, .font: smallMono], range: total)
            if label.location != NSNotFound {
                attr.addAttributes([.foregroundColor: Palette.linkBlue, .font: editorFont], range: label)
            }
            if target.location != NSNotFound {
                attr.addAttributes([
                    .foregroundColor: Palette.marker,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .font: smallMono
                ], range: target)
            }
        }

        applyRegex(Regex.inlineCode, in: full) { match in
            attr.addAttributes([.font: monoFont, .backgroundColor: Palette.codeBackground], range: match.range)
        }
        applyRegex(Regex.codeBlock, in: full) { match in
            attr.addAttributes([.font: monoFont, .backgroundColor: Palette.codeBackground], range: match.range)
        }

        applyRegex(Regex.money, in: full) { match in
            attr.addAttributes([.font: monoFont, .foregroundColor: Palette.money], range: match.range)
        }
        applyRegex(Regex.time, in: full) { match in
            attr.addAttributes([.font: monoFont, .foregroundColor: Palette.dataText], range: match.range)
        }
        applyRegex(Regex.date, in: full) { match in
            attr.addAttributes([.font: monoFont, .foregroundColor: Palette.dataText], range: match.range)
        }
        applyRegex(Regex.tag, in: full) { match in
            attr.addAttributes([
                .foregroundColor: Palette.tagText,
                .backgroundColor: Palette.tagBackground
            ], range: match.range)
        }
        applyRegex(Regex.mention, in: full) { match in
            attr.addAttributes([
                .font: UIFont.boldSystemFont(ofSize: editorFont.pointSize),
                .foregroundColor: Palette.mention
            ], range: match.range)
        }

        // Hanging indent for all supported list/task prefixes
        applyRegex(Regex.listPrefix, in: full) { match in
            let lineRange = match.range(at: 0)
            let prefixRange = match.range(at: 1)
            guard prefixRange.location != NSNotFound else { return }

            let prefix = (full as NSString).substring(with: prefixRange)
            let prefixWidth = (prefix as NSString).size(withAttributes: [.font: monoFont]).width

            let paragraph = NSMutableParagraphStyle()
            paragraph.firstLineHeadIndent = 0
            paragraph.headIndent = prefixWidth

            attr.addAttribute(.paragraphStyle, value: paragraph, range: lineRange)
        }

        textView.attributedText = attr
        textView.selectedRange = selected
    }

    private func applyRegex(_ regex: NSRegularExpression, in text: String, _ body: (NSTextCheckingResult) -> Void) {
        let range = NSRange(location: 0, length: (text as NSString).length)
        regex.matches(in: text, options: [], range: range).forEach(body)
    }

    private func applyGroupStyle(_ regex: NSRegularExpression, group: Int, in text: String, attr: NSMutableAttributedString, attrs: [NSAttributedString.Key: Any]) {
        applyRegex(regex, in: text) { match in
            let range = match.range(at: group)
            if range.location != NSNotFound {
                attr.addAttributes(attrs, range: range)
            }
        }
    }

    private func applyGroupColor(_ regex: NSRegularExpression, group: Int, in text: String, attr: NSMutableAttributedString, color: UIColor, font: UIFont) {
        applyGroupStyle(regex, group: group, in: text, attr: attr, attrs: [.foregroundColor: color, .font: font])
    }

    private func applyGroupTrait(_ regex: NSRegularExpression, group: Int, in text: String, attr: NSMutableAttributedString, trait: UIFontDescriptor.SymbolicTraits) {
        applyRegex(regex, in: text) { match in
            let range = match.range(at: group)
            guard range.location != NSNotFound else { return }
            attr.enumerateAttribute(.font, in: range) { value, subRange, _ in
                guard let font = value as? UIFont else { return }
                var traits = font.fontDescriptor.symbolicTraits
                traits.insert(trait)
                guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return }
                attr.addAttribute(.font, value: UIFont(descriptor: descriptor, size: font.pointSize), range: subRange)
            }
        }
    }
}

private enum Regex {
    static let heading = try! NSRegularExpression(pattern: #"(?m)^(#{1,6})(\s+)(.*)$"#)
    static let doneLine = try! NSRegularExpression(pattern: #"(?m)^\s*[☒☑]\s+.*$"#)
    static let doneTaskLine = try! NSRegularExpression(pattern: #"(?m)^\s*-\s*\[[xX]\]\s+.*$"#)
    static let commentLine = try! NSRegularExpression(pattern: #"(?m)^\s*//.*$"#)

    static let bulletMarkerRed = try! NSRegularExpression(pattern: #"(?m)^\s*([•\-·])\s+"#)
    static let bulletMarkerGray = try! NSRegularExpression(pattern: #"(?m)^\s*([+>])\s+"#)
    static let numberMarker = try! NSRegularExpression(pattern: #"(?m)^\s*(\d+\.)\s+"#)
    static let todoMarker = try! NSRegularExpression(pattern: #"(?m)^\s*(□)\s+"#)

    static let taskLineAny = try! NSRegularExpression(pattern: #"(?m)^\s*-\s*\[(?:\s|x|X|!)\]\s+.*$"#)
    static let taskOpen = try! NSRegularExpression(pattern: #"(?m)^\s*(-)\s*(\[)\s*(\])\s+"#)
    static let taskWarn = try! NSRegularExpression(pattern: #"(?m)^\s*(-)\s*(\[)(!)(\])\s+"#)

    static let squareList = try! NSRegularExpression(pattern: #"(?m)^\s*(■)\s+(.*)$"#)

    static let bold = try! NSRegularExpression(pattern: #"\*\*([^*\n]+)\*\*"#)
    static let italic = try! NSRegularExpression(pattern: #"(?<!\*)\*([^\n]+?)\*(?!\*)"#)
    static let underlineUnderscore = try! NSRegularExpression(pattern: #"_([^_\n]+)_"#)
    static let underlineTilde = try! NSRegularExpression(pattern: #"~([^~\n]+)~"#)
    static let highlightColon = try! NSRegularExpression(pattern: #"::[^:\n]+::"#)
    static let highlightEquals = try! NSRegularExpression(pattern: #"==[^=\n]+=="#)
    static let syntaxMarkers = try! NSRegularExpression(pattern: #"\*\*|\*|_|~|::|==|\[\[|\]\]|\[|\]|\(|\)|\"|“|”|«|»|<del>|</del>"#)

    static let wikiLink = try! NSRegularExpression(pattern: #"\[\[([^\]]+)\]\]"#)
    static let markdownLink = try! NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#)
    static let delTag = try! NSRegularExpression(pattern: #"<del>.*?</del>"#)

    static let doubleQuote = try! NSRegularExpression(pattern: #"\"[^\"\n]+\"|“[^”\n]+”"#)
    static let parenContent = try! NSRegularExpression(pattern: #"\([^()\n]+\)"#)
    static let bracketContent = try! NSRegularExpression(pattern: #"\[[^\[\]\n]+\]"#)
    static let guillemetContent = try! NSRegularExpression(pattern: #"«[^»\n]+»"#)

    static let inlineCode = try! NSRegularExpression(pattern: #"`[^`\n]+`"#)
    static let codeBlock = try! NSRegularExpression(pattern: #"```[\s\S]*?```"#)

    static let money = try! NSRegularExpression(pattern: #"(?<!\w)[\$€£¥]\s?\d[\d,.]*"#)
    static let time = try! NSRegularExpression(pattern: #"\b(?:[01]?\d|2[0-3]):[0-5]\d\b"#)
    static let date = try! NSRegularExpression(pattern: #"\b\d{4}-\d{2}-\d{2}\b|\b\d{4}/\d{1,2}/\d{1,2}\b|\b\d{1,2}/\d{1,2}/\d{2,4}\b|\b\d{1,2}/\d{1,2}\b|\b\d{1,2}-\d{1,2}-\d{2,4}\b|\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},\s+\d{4}\b|\b(19|20)\d{2}\b"#)
    static let tag = try! NSRegularExpression(pattern: #"(?<!\w)#\w+"#)
    static let mention = try! NSRegularExpression(pattern: #"(?<!\w)@\w+"#)
    static let listPrefix = try! NSRegularExpression(pattern: #"(?m)^(\s*(?:[•\-·+>]|■|□|☑|☒|\d+\.|-\s*\[(?:\s|x|X|!)\])\s+)(.*)$"#)
}

private enum Palette {
    static let baseText = UIColor(dynamicLight: "#424242", dark: "#d0d9e5")
    static let marker = UIColor(dynamicLight: "#696e7e", dark: "#7e8ea3")
    static let red = UIColor(hex: "#de4e69")
    static let pink = UIColor(dynamicLight: "#cc4f95", dark: "#e38fc2")
    static let linkBlue = UIColor(dynamicLight: "#4b6fd6", dark: "#8ea3ff")
    static let money = UIColor(dynamicLight: "#406b4f", dark: "#64b075")
    static let dataText = UIColor(dynamicLight: "#5a6472", dark: "#9aa8ba")
    static let tagText = UIColor(dynamicLight: "#255d4d", dark: "#d7efe6")
    static let tagBackground = UIColor(dynamicLight: "#d7efe6", dark: "#255d4d").withAlphaComponent(0.35)
    static let highlight = UIColor(dynamicLight: "#fdef9f", dark: "#706934")
    static let comment = UIColor(dynamicLight: "#737d8a", dark: "#7b8189")
    static let mention = UIColor(dynamicLight: "#4d5f8f", dark: "#8ea3c5")
    static let codeBackground = UIColor(dynamicLight: "#eceff4", dark: "#2e3440")
}

private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }

    convenience init(dynamicLight lightHex: String, dark darkHex: String) {
        self.init { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: darkHex) : UIColor(hex: lightHex)
        }
    }
}

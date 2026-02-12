import SwiftUI
import UIKit

struct EditorDocument: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var text: String
}

struct LeanEditorView: View {
    @State private var documents: [EditorDocument] = [
        .init(title: "Notes", text: "// Lean terminal-editor playground\nfunc hello() {\n    print(\"Hello\")\n}\n"),
        .init(title: "Scratch", text: "# Try editing text here\n")
    ]
    @State private var selectedIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            topBar

            TabView(selection: $selectedIndex) {
                ForEach(Array(documents.enumerated()), id: \.element.id) { index, doc in
                    SyntaxTextView(text: binding(for: index))
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            accessoryBar
        }
        .background(Color(.systemBackground))
    }

    private var topBar: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(documents.enumerated()), id: \.element.id) { index, doc in
                        Button(doc.title) { selectedIndex = index }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(index == selectedIndex ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }

            Button {
                documents.append(.init(title: "Tab \(documents.count + 1)", text: ""))
                selectedIndex = max(0, documents.count - 1)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
    }

    private var accessoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                key("Esc", "\u{1B}")
                key("Tab", "\t")
                key("↤", "\n")
                key("←", "←")
                key("→", "→")
                key("↑", "↑")
                key("↓", "↓")
                key("^C", "^C")
                key("^L", "^L")
                key("^D", "^D")
            }
            .padding(10)
        }
        .background(.ultraThinMaterial)
    }

    private func key(_ title: String, _ insertion: String) -> some View {
        Button(title) {
            guard documents.indices.contains(selectedIndex) else { return }
            documents[selectedIndex].text += insertion
        }
        .buttonStyle(.bordered)
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { documents[index].text },
            set: { documents[index].text = $0 }
        )
    }
}

struct SyntaxTextView: UIViewRepresentable {
    @Binding var text: String

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
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: SyntaxTextView
        init(_ parent: SyntaxTextView) { self.parent = parent }

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

        color(pattern: "\\b(func|let|var|if|else|return|struct|class|import)\\b", in: full, attr: attr, color: .systemBlue)
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

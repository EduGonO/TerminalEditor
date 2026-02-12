import SwiftUI

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
    @StateObject private var editorBridge = EditorBridge()

    var body: some View {
        VStack(spacing: 0) {
            topBar

            TabView(selection: $selectedIndex) {
                ForEach(Array(documents.enumerated()), id: \.element.id) { index, _ in
                    SyntaxTextView(
                        text: binding(for: index),
                        isFocused: selectedIndex == index,
                        bridge: editorBridge
                    )
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            KeyboardAccessoryBarRepresentable(
                onKeyData: { editorBridge.handleKeyData($0) },
                onDismissKeyboard: { editorBridge.dismissKeyboard() },
                onShowKeyboard: { editorBridge.showKeyboard() }
            )
            .frame(height: 74)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
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

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { documents[index].text },
            set: { documents[index].text = $0 }
        )
    }
}

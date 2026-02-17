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
    @State private var showFontPicker = false
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
                onShowKeyboard: { editorBridge.showKeyboard() },
                onMoveLineUp: { editorBridge.moveCurrentLineUp() },
                onMoveLineDown: { editorBridge.moveCurrentLineDown() },
                onIndentLine: { editorBridge.indentCurrentLine() },
                onUnindentLine: { editorBridge.unindentCurrentLine() },
                onCyclePrefix: { editorBridge.cyclePrefixForCurrentSelection() },
                onToggleNippleMode: { editorBridge.toggleNippleMode() },
                nippleControlsLineOps: editorBridge.nippleControlsLineOps
            )
            .frame(height: 74)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .confirmationDialog("Select Font", isPresented: $showFontPicker) {
            ForEach(EditorFontStyle.allCases, id: \.self) { style in
                Button(style.label) { editorBridge.setFontStyle(style) }
            }
        }
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

            HStack(spacing: 6) {
                Button {
                    editorBridge.decreaseFontSize()
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)

                Button(editorBridge.fontStyle.label) {
                    editorBridge.cycleFontStyle()
                }
                .buttonStyle(.bordered)
                .contextMenu {
                    ForEach(EditorFontStyle.allCases, id: \.self) { style in
                        Button(style.label) { editorBridge.setFontStyle(style) }
                    }
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.35)
                        .onEnded { _ in showFontPicker = true }
                )

                Button {
                    editorBridge.increaseFontSize()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)

                Button {
                    documents.append(.init(title: "Tab \(documents.count + 1)", text: ""))
                    selectedIndex = max(0, documents.count - 1)
                } label: {
                    Image(systemName: "plus.square.on.square")
                }
                .buttonStyle(.bordered)
            }
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

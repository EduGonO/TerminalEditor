# Clauntty (Lean Editor Mode)

A stripped-down iOS editor shell focused on one thing: **fast text editing**.

This repo was simplified from a larger SSH/persistent-session terminal app into a lightweight editor surface that is easy to run and adapt for Swift playground-style experimentation.

## What this version keeps

- Multi-tab editing with swipe gestures
- Native text editing + selection + long-press (`UITextView`)
- Syntax highlighting for Swift-like text
- Existing keyboard accessory mechanism (`KeyboardAccessoryView`) wired to editor actions
- Toolbar actions focused on editing: arrows, tab/enter, move line up/down, indent/outdent
- Nipple mode toggle: default cursor control, optional line-edit mode (up/down=move line, left/right=unindent/indent)
- Font controls in top bar: tap font button to cycle Mono/Sans/Serif, long-press to pick from menu, plus +/- for size

## What this version intentionally drops

- SSH connectivity
- rtach session persistence/reconnect protocol
- Port forwarding + in-app web tabs
- SSH key management/authentication
- Connection/session/server management workflows

## Editor files used in this mode

These are the exact files that make the editor-only flow work:

- App shell
  - `Clauntty/ClaunttyApp.swift`
  - `Clauntty/ContentView.swift`
- Editor surface
  - `Clauntty/Views/LeanEditorView.swift`
  - `Clauntty/Views/SyntaxTextView.swift`
  - `Clauntty/Views/EditorBridge.swift`
- Existing toolbar mechanism reused
  - `Clauntty/Views/KeyboardAccessoryView.swift`
  - `Clauntty/Views/KeyboardAccessoryBarRepresentable.swift`

## Run in Xcode (app)

1. Open `Clauntty.xcodeproj`.
2. Select the `Clauntty` scheme.
3. Run on an iOS Simulator (iOS 17+).

## Run in an empty iOS Swift Playground

Use an **iOS App Playground** (not a macOS playground) so UIKit/SwiftUI editor behavior matches.

### 1) Create playground
1. In Xcode: **File → New → Playground → iOS App Playground**.
2. Name it anything (e.g. `LeanEditorPlayground`).

### 2) Copy these files (exact)
Copy the following source files into the playground sources:

1. `Clauntty/Views/KeyboardAccessoryView.swift`
2. `Clauntty/Views/KeyboardAccessoryBarRepresentable.swift`
3. `Clauntty/Views/EditorBridge.swift`
4. `Clauntty/Views/SyntaxTextView.swift`
5. `Clauntty/Views/LeanEditorView.swift`

If your playground only has one file, paste in this order so types resolve in sequence.

### 3) Add minimal logger shim (required by `KeyboardAccessoryView`)
`KeyboardAccessoryView.swift` logs through `Logger.clauntty`. In an empty playground, add this tiny compatibility shim first:

```swift
import os.log

extension Logger {
    static let clauntty = Logger(subsystem: "Playground", category: "Editor")
    func verbose(_ message: String) {}
    func debugOnly(_ message: String) {}
}
```

### 4) Add minimal speech shim (required by `KeyboardAccessoryView`)
The accessory view references `SpeechManager.shared`. If you do not need voice features, add this no-op stub:

```swift
import Foundation
import Combine

@MainActor
final class SpeechManager: ObservableObject {
    static let shared = SpeechManager()
    @Published var audioLevel: Float = 0
    @Published var isModelReady: Bool = false
    @Published var isRecording: Bool = false
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Float = 0

    func startRecording() {}
    func stopRecordingAndTranscribe() async -> String? { nil }
    func cancelRecording() {}
}
```

### 5) Set live view
For playground live view/root view, use:

```swift
import SwiftUI
import PlaygroundSupport

PlaygroundPage.current.setLiveView(LeanEditorView())
```

You now have the same editor stack (tabs + syntax highlighting + line-move/indent toolbar + font family/size controls) running without SSH/rtach/network dependencies.


## Live Markdown Styling (Lean & Fast)

Styles are applied automatically while typing using lightweight regex-based attributed text updates.

| Style | Markdown Syntax | Visual Result |
|---|---|---|
| Bold | `**text**` | Bold text; markers are gray + monospace. |
| Italic | `*text*` | Italic text; markers are gray + monospace. |
| Underline | `_text_` or `~text~` | Single underline. |
| Highlight | `::text::` or `==text==` | Yellow/olive highlight background. |
| Strikethrough line | `☒ text` at line start | Whole line is gray + strikethrough. |
| Comments | `// text` at line start | Gray comment line. |
| Wiki Link | `[[Text inside]]` | Markers gray, inner text pink. |
| Markdown Link | `[text](url)` | Brackets/parentheses gray, `text` blue, `url` gray underlined. |
| Del Tag | `<del>text</del>` | Entire token gray monospace, slightly smaller. |
| Quotes | `"text"`, `“text”`, `«text»`, `(text)`, `[text]` | Markers and inner text gray monospace. |

### Headings
- `#` to `######` at line start produce heading levels (larger to smaller).

### Lists & Tasks
- Bullets: `•`, `-`, `·`
- `+` and `>` list markers (gray)
- Numbered: `1.`
- To-do: `□`
- Done: `☒` and `☑`
- Task forms: `- [ ]`, `- [x]`, `- [X]`, `- [!]` (monospace-aware styling)

List/task markers are colored red (`#de4e69`).

### Smart Data Detection
- Money: `$10`, `$12.50`, `€500`
- Time: `14:00`, `09:30`
- Dates: `2025`, `Jun 6, 2025`, `01/01/2025`, `2025-06-06`
- Extra date formats include `dd/dd/dd`, `dddd/dd/dd`, `dd/dd`, `dd-dd-dd`, `dd-dd-dddd`.
- Tags: `#design`
- Mentions: `@team`

### Code
- Inline code: `` `code` ``
- Code block: triple backticks

Inline/block code uses monospaced font + subtle background.


### Prefix cycling interactions
- Toolbar: use **Prefix** button to cycle list/task prefix state for current line selection.
- Native touch: tap directly on prefix characters at line start (e.g. `-`, `□`, `■`, `- [x]`) to cycle via the same state engine.
- Both entry points share one cycle implementation for deterministic behavior.

# Clauntty (Lean Editor Mode)

A stripped-down iOS editor shell focused on one thing: **fast text editing**.

This repo was simplified from a larger SSH/persistent-session terminal app into a lightweight editor surface that is easy to run and adapt for Swift playground-style experimentation.

## What this version keeps

- Multi-tab editing with swipe gestures
- Native text editing + selection + long-press (`UITextView`)
- Syntax highlighting for Swift-like text
- Existing keyboard accessory mechanism (`KeyboardAccessoryView`) wired to editor actions
- Toolbar actions focused on editing: arrows, tab/enter, move line up/down, indent/outdent

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

You now have the same editor stack (tabs + syntax highlighting + existing accessory toolbar with line-move and indent tools) running without SSH/rtach/network dependencies.

# Clauntty (Lean Editor Mode)

A stripped-down iOS editor shell focused on one thing: **fast text editing**.

This repo was simplified from a larger SSH/persistent-session terminal app into a lightweight editor surface that is easy to run and adapt for Swift playground-style experimentation.

## What this version keeps

- Multi-tab editing with swipe gestures
- Keyboard toolbar with quick-insert keys (Esc, Tab, arrows, ^C/^L/^D, undo/redo)
- Native iOS text selection/long-press behavior (`UITextView`)
- Basic syntax highlighting for Swift-like source text
- Lightweight SwiftUI + UIKit bridge architecture

## What this version intentionally drops

- SSH connectivity
- rtach session persistence and reconnect protocol
- Port forwarding + in-app web tabs
- SSH key management/authentication
- Connection/session/server management workflows

## Core files

- `Clauntty/ClaunttyApp.swift`
- `Clauntty/ContentView.swift`
- `Clauntty/Views/LeanEditorView.swift`

## Run in Xcode (app)

1. Open `Clauntty.xcodeproj`.
2. Select the `Clauntty` scheme.
3. Run on an iOS Simulator (iOS 17+).

## Run in a Swift Playground

You can copy the editor into a UIKit or SwiftUI playground quickly:

1. In Xcode, create **File → New → Playground → iOS App Playground**.
2. Copy the following types from `Clauntty/Views/LeanEditorView.swift` into the playground source:
   - `EditorDocument`
   - `LeanEditorView`
   - `EditorBridge`
   - `SyntaxTextView`
3. Set the playground live view/root view to `LeanEditorView()`.
   - SwiftUI playgrounds: use `PlaygroundPage.current.setLiveView(LeanEditorView())` (or host in `UIHostingController`).
4. Run the playground and edit text directly with multi-tab + toolbar controls.

> Note: the lean editor path is pure Swift/SwiftUI/UIKit and does not require SSH, rtach, or networking services.

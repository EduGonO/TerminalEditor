# Clauntty (Lean Editor Mode)

A stripped-down iOS editor shell focused on one thing: **fast text editing**.

This repo was simplified from a larger SSH/persistent-session terminal app into a lightweight editor surface that is easy to run and adapt for Swift playground-style experimentation.

## What this version keeps

- Multi-tab editing with swipe gestures
- Keyboard toolbar with quick-insert keys (Esc, Tab, arrows, ^C/^L/^D)
- Native iOS text selection/long-press behavior (via `UITextView`)
- Basic syntax highlighting for Swift-like source text
- Lightweight SwiftUI + UIKit bridge architecture

## What this version intentionally drops

- SSH connectivity
- rtach session persistence and reconnect protocol
- Port forwarding + in-app web tabs
- SSH key management/authentication
- Connection/session/server management workflows

## Project focus

The app entry point now launches directly into the isolated editor UI:

- `Clauntty/ClaunttyApp.swift`
- `Clauntty/ContentView.swift`
- `Clauntty/Views/LeanEditorView.swift`

This makes the core editing behavior easy to extract and reuse in a minimal project.

## Run

Open `Clauntty.xcodeproj` in Xcode and run the `Clauntty` scheme on an iOS Simulator (iOS 17+).

## Notes on rendering

The original project includes Ghostty-based terminal rendering components. They remain in the repository history/codebase, but this lean mode routes the app to the isolated editor-only path.

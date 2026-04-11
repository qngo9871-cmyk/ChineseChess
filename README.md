# ChineseChess — Xiangqi

A native iOS app for playing **Xiangqi (Chinese Chess)**, built with Swift and SwiftUI.

## Features

- **Play vs AI** — Challenge a built-in AI opponent at various difficulty levels.
- **Two-Player Mode** — Play locally against a friend on the same device.
- **Traditional Board** — Authentic 9×10 Xiangqi board with river, palace, and all seven piece types.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
ChineseChess/
├── ChineseChessApp.swift   # App entry point
├── ContentView.swift
├── Core/
│   ├── GameModel.swift     # Game state management
│   ├── Board.swift         # Board representation
│   ├── Piece.swift         # Piece types and movement
│   └── AIEngine.swift      # AI opponent logic
└── Views/
    ├── HomeView.swift      # Home / menu screen
    └── GameView.swift      # Main game board view
```

## Getting Started

1. Open `ChineseChess.xcodeproj` in Xcode.
2. Select an iOS simulator or device.
3. Build and run (⌘R).

import Foundation

// MARK: - Position

/// A position on the 9×10 Xiangqi board.
/// Column (x): 0–8 (left to right). Row (y): 0–9 (top/black side to bottom/red side).
struct Position: Equatable, Hashable {
    let x: Int // column 0-8
    let y: Int // row 0-9

    /// Whether this position is within the board bounds.
    var isValid: Bool {
        x >= 0 && x <= 8 && y >= 0 && y <= 9
    }

    /// Whether this position is on the black side of the river (rows 0–4).
    var isBlackSide: Bool { y >= 0 && y <= 4 }

    /// Whether this position is on the red side of the river (rows 5–9).
    var isRedSide: Bool { y >= 5 && y <= 9 }

    /// Whether this position is inside the red palace (cols 3–5, rows 7–9).
    var isInRedPalace: Bool {
        x >= 3 && x <= 5 && y >= 7 && y <= 9
    }

    /// Whether this position is inside the black palace (cols 3–5, rows 0–2).
    var isInBlackPalace: Bool {
        x >= 3 && x <= 5 && y >= 0 && y <= 2
    }
}

// MARK: - PieceColor

/// The two sides in Xiangqi.
enum PieceColor: Equatable, Hashable {
    case red
    case black

    /// The opponent's color.
    var opposite: PieceColor {
        self == .red ? .black : .red
    }

    /// The forward direction for this color (red moves up / decreasing y, black moves down / increasing y).
    var forwardDelta: Int {
        self == .red ? -1 : 1
    }
}

// MARK: - PieceType

/// The seven piece types in Xiangqi, with Chinese character representations.
enum PieceType: Equatable, Hashable {
    case general   // 帥/將 — the king
    case advisor   // 仕/士 — moves diagonally inside palace
    case elephant  // 相/象 — moves 2 steps diagonally, cannot cross river
    case horse     // 馬/馬 — moves in an L-shape, can be blocked
    case chariot   // 車/車 — moves any distance orthogonally (rook)
    case cannon    // 炮/砲 — moves like chariot, captures by jumping exactly one piece
    case soldier   // 兵/卒 — moves forward, sideways after crossing river

    /// Chinese character for the given color.
    func displayCharacter(for color: PieceColor) -> String {
        switch (self, color) {
        case (.general, .red):  return "帥"
        case (.general, .black): return "將"
        case (.advisor, .red):  return "仕"
        case (.advisor, .black): return "士"
        case (.elephant, .red):  return "相"
        case (.elephant, .black): return "象"
        case (.horse, .red):    return "傌"
        case (.horse, .black):  return "馬"
        case (.chariot, .red):  return "俥"
        case (.chariot, .black): return "車"
        case (.cannon, .red):   return "炮"
        case (.cannon, .black): return "砲"
        case (.soldier, .red):  return "兵"
        case (.soldier, .black): return "卒"
        }
    }
}

// MARK: - Piece

/// A Xiangqi piece on the board.
struct Piece: Equatable, Hashable, Identifiable {
    let id: UUID
    let type: PieceType
    let color: PieceColor
    var position: Position

    /// The Chinese character for display.
    var displayCharacter: String {
        type.displayCharacter(for: color)
    }

    init(type: PieceType, color: PieceColor, position: Position) {
        self.id = UUID()
        self.type = type
        self.color = color
        self.position = position
    }
}

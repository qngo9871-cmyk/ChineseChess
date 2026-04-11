import Foundation

// MARK: - Difficulty

enum AIDifficulty: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case medium   = "Medium"
    case expert   = "Expert"

    var id: String { rawValue }

    var requiresPro: Bool {
        switch self {
        case .beginner: return false
        case .medium:   return true
        case .expert:   return true
        }
    }

    var depth: Int {
        switch self {
        case .beginner: return 3
        case .medium:   return 4
        case .expert:   return 5
        }
    }

    /// Chance (0-1) of picking a random move instead of the best one.
    var blunderChance: Double {
        switch self {
        case .beginner: return 0.25
        case .medium:   return 0.0
        case .expert:   return 0.0
        }
    }
}

// MARK: - AIEngine

class AIEngine {

    let difficulty: AIDifficulty
    let color: PieceColor

    init(difficulty: AIDifficulty, color: PieceColor = .black) {
        self.difficulty = difficulty
        self.color = color
    }

    func bestMove(board: Board, completion: @escaping (Position, Position) -> Void) {
        let depth = difficulty.depth
        let aiColor = color
        let boardCopy = board

        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.search(board: boardCopy, depth: depth, color: aiColor)
            DispatchQueue.main.async {
                if let (from, to) = result {
                    completion(from, to)
                }
            }
        }
    }

    // MARK: - Search

    private func search(board: Board, depth: Int, color: PieceColor) -> (Position, Position)? {
        var bestFrom: Position?
        var bestTo: Position?
        var bestScore = Int.min
        var alpha = Int.min
        var allMoves: [(Position, Position)] = []

        for piece in board.pieces where piece.color == color {
            for dest in board.validMoves(for: piece) {
                allMoves.append((piece.position, dest))
                var copy = board
                copy.movePiece(from: piece.position, to: dest)
                let score = minimax(board: copy, depth: depth - 1,
                                    alpha: alpha, beta: Int.max,
                                    maximizing: false, aiColor: color)
                if score > bestScore {
                    bestScore = score
                    bestFrom = piece.position
                    bestTo = dest
                }
                alpha = max(alpha, score)
            }
        }

        // Beginner sometimes picks a random legal move instead of the best.
        if difficulty.blunderChance > 0,
           !allMoves.isEmpty,
           Double.random(in: 0..<1) < difficulty.blunderChance {
            let random = allMoves.randomElement()!
            return random
        }

        if let f = bestFrom, let t = bestTo { return (f, t) }
        return nil
    }

    private func minimax(board: Board, depth: Int,
                         alpha: Int, beta: Int,
                         maximizing: Bool, aiColor: PieceColor) -> Int {
        if depth == 0 {
            return evaluate(board: board, for: aiColor)
        }

        let currentColor = maximizing ? aiColor : aiColor.opposite
        var alpha = alpha
        var beta = beta
        var foundMove = false

        if maximizing {
            var value = Int.min
            for piece in board.pieces where piece.color == currentColor {
                for dest in board.validMoves(for: piece) {
                    foundMove = true
                    var copy = board
                    copy.movePiece(from: piece.position, to: dest)
                    let score = minimax(board: copy, depth: depth - 1,
                                        alpha: alpha, beta: beta,
                                        maximizing: false, aiColor: aiColor)
                    value = max(value, score)
                    alpha = max(alpha, value)
                    if alpha >= beta { return value }
                }
            }
            if !foundMove {
                return board.isInCheck(color: currentColor) ? -100000 + depth : 0
            }
            return value
        } else {
            var value = Int.max
            for piece in board.pieces where piece.color == currentColor {
                for dest in board.validMoves(for: piece) {
                    foundMove = true
                    var copy = board
                    copy.movePiece(from: piece.position, to: dest)
                    let score = minimax(board: copy, depth: depth - 1,
                                        alpha: alpha, beta: beta,
                                        maximizing: true, aiColor: aiColor)
                    value = min(value, score)
                    beta = min(beta, value)
                    if alpha >= beta { return value }
                }
            }
            if !foundMove {
                return board.isInCheck(color: currentColor) ? 100000 - depth : 0
            }
            return value
        }
    }

    // MARK: - Evaluation

    private func evaluate(board: Board, for color: PieceColor) -> Int {
        var score = 0
        for piece in board.pieces {
            let v = pieceValue(piece.type) + positionBonus(piece)
            score += piece.color == color ? v : -v
        }
        return score
    }

    private func pieceValue(_ type: PieceType) -> Int {
        switch type {
        case .general:  return 10000
        case .chariot:  return 900
        case .cannon:   return 500
        case .horse:    return 400
        case .elephant: return 200
        case .advisor:  return 200
        case .soldier:  return 100
        }
    }

    /// Small positional bonus to encourage central / advanced placement.
    private func positionBonus(_ piece: Piece) -> Int {
        switch piece.type {
        case .soldier:
            // Bonus for soldiers that crossed the river
            let crossed = piece.color == .red ? piece.position.isBlackSide : piece.position.isRedSide
            return crossed ? 50 : 0
        case .horse:
            // Prefer central positions
            let cx = abs(piece.position.x - 4)
            return max(0, 3 - cx) * 10
        case .chariot:
            // Rooks on open files are good — approximate with central bonus
            return max(0, 4 - abs(piece.position.x - 4)) * 5
        default:
            return 0
        }
    }
}

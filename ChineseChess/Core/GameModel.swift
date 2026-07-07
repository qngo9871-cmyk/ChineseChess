import Foundation

// MARK: - Game State

/// The high-level state of a game.
enum GameState: Equatable {
    case playing      // normal play
    case check        // current player's General is in check
    case checkmate    // current player is checkmated — they lose
    case stalemate    // current player has no legal moves but is not in check — draw
}

// MARK: - GameModel

/// Observable game model that drives the UI.
/// Red always moves first.
class GameModel: ObservableObject {

    // MARK: Published state

    @Published var board: Board
    @Published var currentTurn: PieceColor = .red
    @Published var gameState: GameState = .playing
    @Published var selectedPiece: Piece?
    @Published var validMovesForSelected: [Position] = []
    @Published var winner: PieceColor?

    // MARK: Init

    init() {
        board = Board()
    }

    // MARK: - Selection & movement

    /// Called when the user taps a board position.
    func tap(at position: Position) {
        // Game is over — ignore taps.
        guard gameState == .playing || gameState == .check else { return }

        if let selected = selectedPiece {
            // A piece is already selected.
            if validMovesForSelected.contains(position) {
                // Execute the move.
                executeMove(from: selected.position, to: position)
            } else if let tapped = board.piece(at: position), tapped.color == currentTurn {
                // Tapped a different friendly piece — reselect.
                select(piece: tapped)
            } else {
                // Tapped an invalid square — deselect.
                deselect()
            }
        } else {
            // Nothing selected yet.
            if let tapped = board.piece(at: position), tapped.color == currentTurn {
                select(piece: tapped)
            }
        }
    }

    /// Select a piece and compute its valid moves.
    private func select(piece: Piece) {
        selectedPiece = piece
        validMovesForSelected = board.validMoves(for: piece)
    }

    /// Clear selection.
    private func deselect() {
        selectedPiece = nil
        validMovesForSelected = []
    }

    /// Execute a move, switch turns, and re-evaluate the game state.
    func executeMove(from origin: Position, to destination: Position) {
        board.movePiece(from: origin, to: destination)
        deselect()
        switchTurn()
        updateGameState()
    }

    /// Switch to the other player's turn.
    private func switchTurn() {
        currentTurn = currentTurn.opposite
    }

    // MARK: - Game state evaluation

    /// Called after every move to check for check / checkmate / stalemate.
    private func updateGameState() {
        let inCheck = board.isInCheck(color: currentTurn)
        let hasLegalMove = board.hasAnyLegalMove(for: currentTurn)

        if inCheck && !hasLegalMove {
            // Checkmate — the player who just moved wins.
            gameState = .checkmate
            winner = currentTurn.opposite
        } else if !inCheck && !hasLegalMove {
            // Stalemate — draw.
            gameState = .stalemate
            winner = nil
        } else if inCheck {
            gameState = .check
        } else {
            gameState = .playing
        }
    }

    // MARK: - Game control

    /// Reset the board to the starting position.
    func newGame() {
        board = Board()
        currentTurn = .red
        gameState = .playing
        selectedPiece = nil
        validMovesForSelected = []
        winner = nil
    }

    /// The current player resigns — the opponent wins.
    func resign() {
        gameState = .checkmate
        winner = currentTurn.opposite
    }
}

#if DEBUG
// MARK: - Screenshot capture helpers (DEBUG only; launch args never set in production)
extension GameModel {

    private func pieceValue(_ t: PieceType) -> Int {
        switch t {
        case .general: return 10000
        case .chariot: return 900
        case .cannon:  return 500
        case .horse:   return 400
        case .elephant, .advisor: return 200
        case .soldier: return 100
        }
    }

    /// Show a piece as selected with its legal-move dots (used for the "highlights" shot).
    func forceSelect(at pos: Position) {
        guard let p = board.piece(at: pos) else { return }
        selectedPiece = p
        validMovesForSelected = board.validMoves(for: p)
    }

    /// A short, all-legal development opening that keeps every piece on the board —
    /// central cannons, screen horses, activated chariots. Tidy "real game" look.
    private func playOpening() {
        let moves: [(Int, Int, Int, Int)] = [
            (7, 7, 4, 7),  // red   central cannon
            (7, 0, 6, 2),  // black screen horse (right)
            (7, 9, 6, 7),  // red   right horse out
            (1, 0, 2, 2),  // black left horse out
            (8, 9, 7, 9),  // red   right chariot shift
            (8, 0, 7, 0),  // black right chariot shift
            (7, 9, 7, 8),  // red   chariot up one
            (7, 0, 7, 1),  // black chariot down one
        ]
        for (fx, fy, tx, ty) in moves {
            board.movePiece(from: Position(x: fx, y: fy), to: Position(x: tx, y: ty))
            currentTurn = currentTurn.opposite
        }
    }

    /// Development-biased legal self-play — evolves the position while keeping most
    /// pieces (only captures clearly-winning material). Deterministic.
    private func selfPlay(plies: Int) {
        for _ in 0..<plies {
            guard board.hasAnyLegalMove(for: currentTurn) else { break }
            var bestFrom: Position?, bestTo: Position?, bestScore = Int.min
            for p in board.pieces(for: currentTurn) {
                for dest in board.validMoves(for: p) {
                    var score = 0
                    if let cap = board.piece(at: dest) { score += pieceValue(cap.type) / 40 }
                    // advance toward the opponent + favour central files, off the back rank
                    score += (currentTurn == .red ? (9 - dest.y) : dest.y)
                    score -= abs(dest.x - 4)
                    if p.position.y == (currentTurn == .red ? 9 : 0) { score += 3 } // develop back rank
                    // deterministic tiebreak by coordinates
                    let tie = dest.y * 9 + dest.x
                    if score > bestScore || (score == bestScore && tie < ((bestTo.map { $0.y*9+$0.x }) ?? .max)) {
                        bestScore = score; bestFrom = p.position; bestTo = dest
                    }
                }
            }
            if let f = bestFrom, let t = bestTo {
                board.movePiece(from: f, to: t); currentTurn = currentTurn.opposite
            } else { break }
        }
    }

    /// Entry point. name: board | opening | select | midgame
    func captureSetup(_ name: String) {
        newGame()
        switch name {
        case "opening":
            playOpening()
        case "select":
            playOpening()
            forceSelect(at: Position(x: 7, y: 8))   // activated red chariot — long move line
        case "midgame":
            playOpening(); selfPlay(plies: 10)
        default:
            break   // "board" = fresh starting position
        }
        // Refresh turn indicator / check status for the seeded position.
        let inCheck = board.isInCheck(color: currentTurn)
        gameState = inCheck ? .check : .playing
    }
}
#endif

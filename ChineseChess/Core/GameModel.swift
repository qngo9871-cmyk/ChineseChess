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

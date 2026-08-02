import Foundation

/// Represents the 9×10 Xiangqi board and handles all move generation / validation.
///
/// Uses a flat 90-element grid for O(1) lookups and fast value-type copies.
struct Board {

    // MARK: - Constants

    static let columns = 9
    static let rows    = 10

    // MARK: - State

    /// All pieces currently on the board.
    var pieces: [Piece]

    /// Flat grid (row-major, index = y*9 + x) for O(1) lookups. Nil means empty.
    private var grid: [Piece?]

    // MARK: - Init

    init() {
        let initial = Board.initialPieces()
        self.pieces = initial
        self.grid = Board.buildGrid(from: initial)
    }

    init(pieces: [Piece]) {
        self.pieces = pieces
        self.grid = Board.buildGrid(from: pieces)
    }

    private static func buildGrid(from pieces: [Piece]) -> [Piece?] {
        var g = [Piece?](repeating: nil, count: 90)
        for p in pieces {
            g[p.position.y * 9 + p.position.x] = p
        }
        return g
    }

    // MARK: - Grid access

    @inline(__always)
    func piece(at pos: Position) -> Piece? {
        grid[pos.y * 9 + pos.x]
    }

    @inline(__always)
    private func gridAt(_ x: Int, _ y: Int) -> Piece? {
        grid[y * 9 + x]
    }

    func pieces(for color: PieceColor) -> [Piece] {
        pieces.filter { $0.color == color }
    }

    func general(for color: PieceColor) -> Piece? {
        pieces.first { $0.type == .general && $0.color == color }
    }

    // MARK: - Move execution

    @discardableResult
    mutating func movePiece(from origin: Position, to dest: Position) -> Piece? {
        let destIdx = dest.y * 9 + dest.x
        let origIdx = origin.y * 9 + origin.x
        let captured = grid[destIdx]

        if let captured {
            pieces.removeAll { $0.id == captured.id }
        }

        if let idx = pieces.firstIndex(where: { $0.position == origin }) {
            pieces[idx].position = dest
            grid[destIdx] = pieces[idx]
        }
        grid[origIdx] = nil

        return captured
    }

    // MARK: - Valid move generation

    /// Legal moves for a piece (filters out moves that leave own king in check).
    func validMoves(for piece: Piece) -> [Position] {
        rawMoves(for: piece).filter { dest in
            var copy = self
            copy.movePiece(from: piece.position, to: dest)
            return !copy.isInCheck(color: piece.color)
        }
    }

    /// Whether the given color has any legal move. Returns early on first hit.
    func hasAnyLegalMove(for color: PieceColor) -> Bool {
        for p in pieces where p.color == color {
            for dest in rawMoves(for: p) {
                var copy = self
                copy.movePiece(from: p.position, to: dest)
                if !copy.isInCheck(color: color) { return true }
            }
        }
        return false
    }

    // MARK: - Check detection (fast, pattern-based)

    /// Checks if `color`'s General is in check by looking outward from the king's
    /// position for specific attack patterns — much faster than generating all
    /// opponent moves.
    func isInCheck(color: PieceColor) -> Bool {
        guard let king = general(for: color) else { return false }
        let kx = king.position.x
        let ky = king.position.y
        let enemy = color.opposite

        // 1. Chariot / Cannon / Flying General along orthogonal lines
        let dirs: [(Int, Int)] = [(1,0),(-1,0),(0,1),(0,-1)]
        for (dx, dy) in dirs {
            var x = kx + dx, y = ky + dy
            var screenCount = 0
            while x >= 0 && x <= 8 && y >= 0 && y <= 9 {
                if let occ = gridAt(x, y) {
                    if screenCount == 0 {
                        if occ.color == enemy {
                            // Direct line of sight: chariot attacks, or opposing general (flying general)
                            if occ.type == .chariot { return true }
                            if occ.type == .general { return true }
                        }
                        screenCount = 1
                    } else {
                        // Behind one screen: cannon attacks
                        if occ.color == enemy && occ.type == .cannon { return true }
                        break
                    }
                }
                x += dx; y += dy
            }
        }

        // 2. Horse attacks — check all 8 positions a horse could attack from,
        //    verifying the blocking leg is clear.
        let horseMoves: [(fx: Int, fy: Int, bx: Int, by: Int)] = [
            (-1, -2, 0,  1), (1, -2, 0,  1),
            (-1,  2, 0, -1), (1,  2, 0, -1),
            (-2, -1, 1,  0), (-2,  1, 1,  0),
            ( 2, -1, -1, 0), ( 2,  1, -1, 0),
        ]
        for hm in horseMoves {
            let hx = kx + hm.fx, hy = ky + hm.fy
            guard hx >= 0 && hx <= 8 && hy >= 0 && hy <= 9 else { continue }
            // The blocking square is relative to the horse's position, not the king's.
            // A horse at (hx,hy) attacking (kx,ky) means the horse moved with delta (-hm.fx, -hm.fy).
            // Its blocking leg is the first orthogonal step of that move — i.e. one step from
            // the horse *toward* the king along the move's long axis (bx/by point that way).
            let bx = hx + hm.bx, by = hy + hm.by
            guard bx >= 0 && bx <= 8 && by >= 0 && by <= 9 else { continue }
            if gridAt(bx, by) != nil { continue } // leg is blocked, horse can't reach
            if let occ = gridAt(hx, hy), occ.color == enemy && occ.type == .horse {
                return true
            }
        }

        // 3. Soldier attack — enemy soldier can attack from forward or sideways (if crossed river).
        let soldierForward = color == .red ? -1 : 1  // direction enemy soldier moves toward our king
        // Enemy soldier directly in front of our king (from enemy's perspective, that's behind our king)
        let sy = ky + soldierForward
        if sy >= 0 && sy <= 9 {
            if let occ = gridAt(kx, sy), occ.color == enemy && occ.type == .soldier {
                return true
            }
        }
        // Enemy soldier attacking sideways (only if it crossed river)
        for sdx in [-1, 1] {
            let sx = kx + sdx
            guard sx >= 0 && sx <= 8 else { continue }
            if let occ = gridAt(sx, ky), occ.color == enemy && occ.type == .soldier {
                // Soldier can only attack sideways if it has crossed the river
                let crossed = enemy == .red ? occ.position.isBlackSide : occ.position.isRedSide
                if crossed { return true }
            }
        }

        return false
    }

    // MARK: - Raw move generation

    func rawMoves(for piece: Piece) -> [Position] {
        switch piece.type {
        case .general:  return generalMoves(piece)
        case .advisor:  return advisorMoves(piece)
        case .elephant: return elephantMoves(piece)
        case .horse:    return horseMoves(piece)
        case .chariot:  return chariotMoves(piece)
        case .cannon:   return cannonMoves(piece)
        case .soldier:  return soldierMoves(piece)
        }
    }

    // MARK: General — stays in palace, one step orthogonal
    private func generalMoves(_ p: Piece) -> [Position] {
        let deltas = [(0,-1),(0,1),(-1,0),(1,0)]
        return deltas.compactMap { dx, dy in
            let dest = Position(x: p.position.x+dx, y: p.position.y+dy)
            guard dest.isValid, isInPalace(dest, for: p.color),
                  !isFriendly(dest, p.color) else { return nil }
            return dest
        }
    }

    // MARK: Advisor — stays in palace, one step diagonal
    private func advisorMoves(_ p: Piece) -> [Position] {
        let deltas = [(-1,-1),(-1,1),(1,-1),(1,1)]
        return deltas.compactMap { dx, dy in
            let dest = Position(x: p.position.x+dx, y: p.position.y+dy)
            guard dest.isValid, isInPalace(dest, for: p.color),
                  !isFriendly(dest, p.color) else { return nil }
            return dest
        }
    }

    // MARK: Elephant — 2 steps diagonal, own side only, blocked by eye
    private func elephantMoves(_ p: Piece) -> [Position] {
        let deltas = [(-2,-2),(-2,2),(2,-2),(2,2)]
        return deltas.compactMap { dx, dy in
            let dest = Position(x: p.position.x+dx, y: p.position.y+dy)
            guard dest.isValid else { return nil }
            if p.color == .red  && !dest.isRedSide  { return nil }
            if p.color == .black && !dest.isBlackSide { return nil }
            let ex = p.position.x+dx/2, ey = p.position.y+dy/2
            if gridAt(ex, ey) != nil { return nil }
            guard !isFriendly(dest, p.color) else { return nil }
            return dest
        }
    }

    // MARK: Horse — L-shape with hobble leg
    private func horseMoves(_ p: Piece) -> [Position] {
        let moveSets: [(ox:Int,oy:Int,fx:Int,fy:Int)] = [
            (0,-1,-1,-2),(0,-1,1,-2),(0,1,-1,2),(0,1,1,2),
            (-1,0,-2,-1),(-1,0,-2,1),(1,0,2,-1),(1,0,2,1),
        ]
        return moveSets.compactMap { ms in
            let bx = p.position.x+ms.ox, by = p.position.y+ms.oy
            guard bx >= 0 && bx <= 8 && by >= 0 && by <= 9 else { return nil }
            if gridAt(bx, by) != nil { return nil }
            let dest = Position(x: p.position.x+ms.fx, y: p.position.y+ms.fy)
            guard dest.isValid, !isFriendly(dest, p.color) else { return nil }
            return dest
        }
    }

    // MARK: Chariot — slides orthogonally
    private func chariotMoves(_ p: Piece) -> [Position] {
        var moves = [Position]()
        moves.reserveCapacity(17)
        for (dx,dy) in [(1,0),(-1,0),(0,1),(0,-1)] {
            var x = p.position.x+dx, y = p.position.y+dy
            while x >= 0 && x <= 8 && y >= 0 && y <= 9 {
                if let occ = gridAt(x, y) {
                    if occ.color != p.color { moves.append(Position(x:x,y:y)) }
                    break
                }
                moves.append(Position(x:x,y:y))
                x += dx; y += dy
            }
        }
        return moves
    }

    // MARK: Cannon — slides to move, jumps one screen to capture
    private func cannonMoves(_ p: Piece) -> [Position] {
        var moves = [Position]()
        moves.reserveCapacity(17)
        for (dx,dy) in [(1,0),(-1,0),(0,1),(0,-1)] {
            var x = p.position.x+dx, y = p.position.y+dy
            var jumped = false
            while x >= 0 && x <= 8 && y >= 0 && y <= 9 {
                if let occ = gridAt(x, y) {
                    if !jumped { jumped = true }
                    else {
                        if occ.color != p.color { moves.append(Position(x:x,y:y)) }
                        break
                    }
                } else if !jumped {
                    moves.append(Position(x:x,y:y))
                }
                x += dx; y += dy
            }
        }
        return moves
    }

    // MARK: Soldier — forward; forward+sideways after crossing river
    private func soldierMoves(_ p: Piece) -> [Position] {
        var deltas = [(0, p.color.forwardDelta)]
        let crossed = p.color == .red ? p.position.isBlackSide : p.position.isRedSide
        if crossed { deltas.append(contentsOf: [(-1,0),(1,0)]) }
        return deltas.compactMap { dx, dy in
            let dest = Position(x: p.position.x+dx, y: p.position.y+dy)
            guard dest.isValid, !isFriendly(dest, p.color) else { return nil }
            return dest
        }
    }

    // MARK: - Helpers

    @inline(__always)
    private func isInPalace(_ pos: Position, for color: PieceColor) -> Bool {
        color == .red ? pos.isInRedPalace : pos.isInBlackPalace
    }

    @inline(__always)
    private func isFriendly(_ pos: Position, _ color: PieceColor) -> Bool {
        if let p = grid[pos.y * 9 + pos.x], p.color == color { return true }
        return false
    }

    // MARK: - Initial setup

    static func initialPieces() -> [Piece] {
        var r = [Piece]()
        r.reserveCapacity(32)

        func sym(_ t: PieceType, _ c: PieceColor, _ x: Int, _ y: Int) {
            r.append(Piece(type:t,color:c,position:Position(x:x,y:y)))
            if x != 8-x { r.append(Piece(type:t,color:c,position:Position(x:8-x,y:y))) }
        }

        sym(.chariot,.black,0,0); sym(.horse,.black,1,0); sym(.elephant,.black,2,0)
        sym(.advisor,.black,3,0)
        r.append(Piece(type:.general,color:.black,position:Position(x:4,y:0)))
        sym(.cannon,.black,1,2)
        for x in stride(from:0,through:8,by:2) { r.append(Piece(type:.soldier,color:.black,position:Position(x:x,y:3))) }

        sym(.chariot,.red,0,9); sym(.horse,.red,1,9); sym(.elephant,.red,2,9)
        sym(.advisor,.red,3,9)
        r.append(Piece(type:.general,color:.red,position:Position(x:4,y:9)))
        sym(.cannon,.red,1,7)
        for x in stride(from:0,through:8,by:2) { r.append(Piece(type:.soldier,color:.red,position:Position(x:x,y:6))) }

        return r
    }
}

# ChineseChess (Xiangqi)

Native iOS app for playing Xiangqi (Chinese Chess). Play vs AI or two-player local mode on an authentic 9×10 board.

## Stack
- iOS (Swift/SwiftUI), iOS 17.0+
- StoreKit (Products.storekit present)
- No external APIs

## Project Structure
- `ChineseChess/Core/` — GameModel, Board, Piece, AIEngine
- `ChineseChess/Views/` — HomeView, GameView
- `rebuild.sh` — rebuild script

## Key Decisions
- AI opponent with difficulty levels
- Two-player local mode (same device)
- Traditional board with river, palace, all 7 piece types

## Related apps
`~/Projects/Janggi` (Korean Chess) is forked from this engine and shared the exact
horse-check sign-inversion bug fixed 2026-08-03 below — copy-pasted verbatim along with
the rest of `Board.swift`. If `Board.isInCheck` changes here again, check whether
Janggi's copy needs the same fix (it has diverged since — Janggi's elephant can check,
Xiangqi's can't — so don't assume the files are still identical, diff first).

## Current State
- **2026-08-03 — v1.0.5 (build 15), critical checkmate-detection bug fix, SUBMITTED.** A user reported the AI (Beginner difficulty) declaring checkmate after only a move or two. Root-caused to `Board.isInCheck` in `ChineseChess/Core/Board.swift`: the horse ("knight") check-detection pattern computed the blocking-leg square with every offset **sign-inverted** — it checked the mirror-image square instead of the real blocking point. Verified via an independent Python port cross-validated against a from-scratch ground-truth checker (raw-move reverse lookup) over 500 random games (80 plies each): the bug caused **49 divergences** — both false checks/checkmates (a blocked horse still counted as checking) and missed real checks/checkmates (an unblocked horse not counted). This affects **every difficulty level**, not just Beginner, since all three share the same `Board.isInCheck`/`hasAnyLegalMove` code path — Beginner's high blunder rate (25%) and the AI's endgame "mate drive" (which deliberately marches horses toward the enemy general once material-ahead, see `AIEngine.evaluate`) just made it manifest fastest there. Fixed the leg-offset signs in the `horseMoves` tuple list; re-validated the same 500-game harness at **0 mismatches** against ground truth, and confirmed no other divergences exist in chariot/cannon/soldier/flying-general check logic (also cross-validated, 0 mismatches). Confirmed literal "checkmate on move 1" is not reproducible (no piece can reach horse-check range of the opponent's general in one ply) — the user's report was an early-but-not-first-move occurrence. Bumped MARKETING_VERSION 1.0.4→1.0.5 / CURRENT_PROJECT_VERSION 14→15. Archived/exported/uploaded via API-key auth (see `ExportOptions.plist`, newly added — this app didn't have one before); submission via `new_version.py` + one-off `reviewSubmissions` calls (Pro IAP already approved → no re-tick, no screenshot changes needed for a pure bug-fix release). **SUBMITTED, WAITING_FOR_REVIEW** — app `6762035708`, version `1.0.5` (id `dad331ea-e681-4028-8f26-b2ec078b960d`), build `15`/`e95822ce-6152-4eea-83aa-1aedc067b7a1` attached, reviewSubmission `03a5a74c-bc7c-4421-9308-35fa24a9d880`. Note: this version also carries the zh-Hant localization from v1.0.4 (added 2026-07-08) — its `whatsNew` needed setting separately from `en-US` (translated release note) since `new_version.py` only patches the `en*` locale; any future non-English-only submission via that script needs the same manual follow-up per extra locale, or the script should be extended to loop all locales.
- **2026-07-07 — v1.0.3 (build 13) screenshot rework, SUBMITTED (WAITING_FOR_REVIEW).** New 5-shot best-first set in `screenshots/v2/` (home / authentic board / developed opening / tap-to-see-legal-moves / mid-battle; cinnabar band) via `capture_shots.py` at repo root. Added `CC_CAPTURE=home|board|opening|select|midgame` DEBUG hook: `GameModel.captureSetup` (a `playOpening` 8-move all-legal development sequence + development-biased legal `selfPlay` + `forceSelect` to show legal-move dots) driven from `GameView`/`HomeView` `onAppear` — all `#if DEBUG`, inert in production. DEBUG forces isPro (no locks). Bumped pbxproj MARKETING_VERSION 1.0.2→1.0.3 / CURRENT_PROJECT_VERSION 12→13. Resubmitted via `~/asc-tools/new_version.py` + `replace_shots.py` (Pro IAP already approved → no re-tick).
- Core game engine and UI built
- In-app purchase (Pro unlock) implemented with StoreKit 2
- App is live on App Store (v1.0); build 9 rejected for Guideline 2.1(b) — IAP not linked to version page, now resolved
- v1.0.1 build 11 archived 2026-04-28 with AI improvements + IAP fix; pending upload to App Store Connect as a new version
- AI rework (2026-04-28): tropism + king-mobility eval terms drive endgame to checkmate; capture-priority move ordering for faster alpha-beta; repetition tracking (last 8 position hashes, –150 penalty) to stop piece-shuffling; Expert reduced 5→4 with Medium gaining 5% blunder for distinct difficulty ladder

## Instructions for Claude Code
At the end of every session, update the Current State section to reflect progress made.

## Reasoning Mode
You are a Xiangqi master, a game AI engineer, an iOS game developer, a UX designer for board games, and a student of Chinese cultural aesthetics. You understand that Xiangqi is not just chess with different pieces — it has its own strategic depth, cultural weight, and community of serious players who will notice if you get it wrong.

Your instincts come from multiple disciplines:
- As a Xiangqi master, you know the rules precisely — including edge cases like perpetual check, chasing rules, and stalemate conventions that differ from Western chess
- As a game AI engineer, you think about search depth, evaluation functions, difficulty scaling, and avoiding exploitable patterns that make the AI feel cheap or unrealistic
- As an iOS game developer, you think about touch targets, animation timing, board rendering performance, and the satisfying tactile feel of a well-made move
- As a board game UX designer, you know that clarity of legal moves, undo behaviour, and game state communication separate a great app from a frustrating one
- As a student of Chinese aesthetics, you understand that the visual design should feel authentic — ink, wood, stone — not a Western chess skin with renamed pieces
- As a competitive games expert, you understand what keeps players coming back: fair challenge, clear feedback, and the sense that the AI is a worthy opponent

If a requested approach would produce unrealistic AI play, break rule edge cases, or feel inauthentic to the game, say so first. If you see a better approach, say so before proceeding.

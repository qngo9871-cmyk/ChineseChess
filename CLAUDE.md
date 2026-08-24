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
- **2026-08-24 (later same day) — vision QA found the v1.0.7 submission's own home
  screenshot has a real UI bug: the difficulty picker's `.frame(maxWidth: 280)`
  truncates "Beginner/Medium/Expert" to "Begin…/Mediu… 🔒/Expert 🔒" once Medium+Expert
  both show their (permanent, trial-unaffected) lock icon — this is the *normal*
  state for this app, not just a post-trial edge case, so **the screenshot that
  already shipped to ASC on v1.0.7 shows this bug**. Fixed `Views/HomeView.swift`
  (widened to `maxWidth: 340`) and `capture_shots.py` (added `simctl erase` for
  deterministic trial-day capture + an 8s settle wait to avoid a first-boot system
  notification landing in frame). Recaptured and verified all 10 screenshots (5 ×
  en/zh-Hant) — no truncation, no stray UI. **Pulled, fixed, and resubmitted per
  standing user policy** (found post-submit bug → cancel → fix → resubmit, applies to
  all apps): canceled the v1.0.7 reviewSubmission (`84cfad89-...`,
  `CANCELING`→`COMPLETE`, version dropped to `DEVELOPER_REJECTED`), bumped to
  **v1.0.8 (build 18)**, archived/exported/uploaded (Delivery UUID
  `380f0fb2-5298-4f75-98ec-1df5906a9472`, processed `VALID`), attached to the same
  appStoreVersion record (versionString PATCHed 1.0.7→1.0.8), pushed the corrected
  screenshots via `asc_push_chinesechess_screenshots.py`, updated `whatsNew` (both
  locales, describes the fix), created a new reviewSubmission
  `2ad90172-3e30-42d8-a0f7-62447ae6e003` and submitted. **Verified: WAITING_FOR_REVIEW
  as v1.0.8.**
- **2026-08-24 — v1.0.7 (build 17), full remediation pass, SUBMITTED.** Found by the new
  portfolio-wide `~/asc-tools/compliance_gate.py`: this app had the DEBUG isPro
  double-gating bug, zero onboarding, zero in-app localization despite a real zh-Hant ASC
  listing since v1.0.4, and (found only via manual testing, not the gate) a genuine iPad
  layout bug. Fixed all four:
  - **DEBUG isPro double-gating**: `PurchaseManager.updateEntitlementStatus()`'s bare
    `isPro = true` replaced with the same capture-mode-exempted pattern already used in
    SamLoc/Fanorona/Dara/Surakarta (`isPro = CC_CAPTURE != nil && CC_CAPTURE != "home"`).
  - **Onboarding**: built `Views/OnboardingView.swift`, a 4-page walkthrough (two-phase
    structure, the 九宮 palace restriction, the seven piece types, checkmate), wired via
    `hasSeenOnboarding` in `ChineseChessApp.swift`'s new `rootView`, re-accessible from
    Home via "How to Play".
  - **Real in-app localization**: built `Core/Localization.swift` (manual bundle-swap
    `LocalizationManager`, same pattern as Dara/Surakarta/Klotski) plus `en.lproj`/
    `zh-Hant.lproj` `Localizable.strings` (Traditional, matching the existing ASC listing
    locale — not zh-Hans like most of the portfolio). Every user-facing string in
    HomeView/GameView/UpgradeView/OnboardingView now routes through `L()`; grammar-trap
    templates (`game.wins`/`game.turn`/`game.incheck`) use `String(format:)` substitution,
    not concatenation, after the SamLoc "You wins" bug class.
  - **iPad layout bug, found via actual iPad-simulator testing (not just the gate)**:
    `GameView.cellSize(in:)` computed board-cell size from a fixed `boardPadding` (24pt)
    that didn't scale with cellSize. On iPhone this was invisible (cellSize small enough
    that piece radius stayed under 24pt), but on iPad's much larger canvas the outermost
    column of pieces — drawn as circles centered on the edge grid lines — extended tens of
    points past the fixed margin and clipped off-screen on both sides. **First attempt was
    wrong**: tried fixing this by restricting `TARGETED_DEVICE_FAMILY` to iPhone-only, but
    Apple rejected the upload (error 90101) — you cannot drop a previously-declared device
    family in an update, ever. Reverted to `"1,2"` and instead fixed the actual math:
    `cellSize` now divides by `(columns-1+pieceScale)` instead of `(columns-1)`, reserving
    piece-radius margin proportional to cellSize rather than a fixed constant. Verified via
    real iPad Pro 13" and iPhone 17 Pro Max simulator screenshots, no clipping either device,
    no regression.
  - Also fixed a missing `AccentColor` (silent build warning, unrelated pre-existing gap)
    and recaptured all 5 marketing screenshots in both `en`/`zh-Hant` via new
    `capture_shots.py` (replaces the old `/Users/user/ChineseChess`-hardcoded stale one) —
    zh-Hant had **zero** screenshots on every version ever shipped until now.
  - Bumped `MARKETING_VERSION` 1.0.6→**1.0.7**, `CURRENT_PROJECT_VERSION` 16→**17**.
    Archived/exported/uploaded via API-key auth, `new_version.py` + zh-Hant `whatsNew`
    patch + `asc_push_chinesechess_screenshots.py` (new) + one-off `reviewSubmissions`
    calls. Pro IAP already `APPROVED`, no re-tick needed (routine update). **SUBMITTED,
    WAITING_FOR_REVIEW** — app `6762035708`, version `1.0.7` (id
    `46429af6-e673-433a-a2ca-5fd3ea9034e9`), build `17`/`603d75e3-8537-49d3-8e51-bd0851cb229c`
    attached, reviewSubmission `84cfad89-cd97-4e68-9a5b-2dde5e483710`.
- **2026-08-09 — v1.0.6 (build 16), 7-day free-trial paywall pilot, SUBMITTED.** Sales-report analysis showed 43 downloads with zero IAP conversions, while sibling apps in the portfolio convert at 2-11% from similar/smaller volumes — ruled out a broken-purchase bug (IAP `state=APPROVED`, paywall correctly wired into `HomeView`) and concluded the free-forever Beginner AI difficulty was satisfying casual players with no reason to upgrade. Added a 7-day trial clock (`PurchaseManager.trialActive`/`trialDaysRemaining`, backed by a `firstLaunchDate` UserDefaults key) — during the trial the app behaves exactly as before, but once it expires `HomeView.isLocked(_:)` now gates **Beginner difficulty too**, not just Medium/Expert/Play vs Friend. Existing installs (no stored `firstLaunchDate` from a pre-trial build) get the clock started by this update rather than being locked out immediately. `UpgradeView` copy switches to "Your Free Trial Has Ended" once the trial is over. Verified both trial-active and trial-expired UI states live in Simulator (temporarily shortened `trialDuration` for the expired-state screenshot, then reverted before shipping — see git diff for the real 7-day constant). Bumped MARKETING_VERSION 1.0.5→1.0.6 / CURRENT_PROJECT_VERSION 15→16. Archived/exported/uploaded via API-key auth, submitted via `new_version.py` + one-off `reviewSubmissions` calls (zh-Hant localization needed its own `whatsNew` patch again, same gotcha as v1.0.5). **SUBMITTED, WAITING_FOR_REVIEW** — app `6762035708`, version `1.0.6` (id `b148c198-350e-4026-8ac7-b99f7bd4584f`), build `16`/`bd2d7064-f451-4e10-b977-e9eb351a6d0d` attached, reviewSubmission `902e0225-8fb3-4cfa-9d49-513ada7171ba`. **This is a portfolio pilot** — 17 other apps share the same free-tier-forever + `requiresPro` pattern (Janggi, Makruk, Hanafuda Koi-Koi, Shogi Do, Fanorona, SamLoc, Pallanguzhi, Igisoro, Omweso, ToguzKorgool, Surakarta, Dara, Bao, Chan, CoCaNgua, OAnQuan, PhomTaLa, SapXam, TienLen) but the user chose to wait ~2-3 weeks for real conversion data on this app before deciding whether to roll it out further. See memory `project_chinesechess_trial_paywall_pilot`.
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

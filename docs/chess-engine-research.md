# Chess Engine Research

## Official chess.js source

Source URL: https://github.com/jhlywa/chess.js/

The official repository describes chess.js as a TypeScript chess library for move generation and validation, piece placement and movement, and check/checkmate/stalemate detection. It explicitly states that it provides everything except the AI engine. The repository currently shows release v1.4.0 and a recent commit adding `isCheck()` to the Move API. This makes chess.js appropriate for replacing the current hand-written move logic, while a separate AI engine is required if the app should play against the user.

## Implication for Mirror Scorpion v3

Use chess.js as the rules authority for legal moves, check, checkmate, stalemate, castling, en passant, promotion, FEN, and PGN. Keep the existing Royal Dark board presentation, clock, move history, and captured pieces as the UI layer. A literal 3D board requires a graphics layer such as Three.js/Expo GL or a native 3D library; it should not be represented as a flat 2D board with perspective-only styles.

## Official expo-three source

Source URL: https://github.com/expo/expo-three

The official Expo repository states that expo-three bridges Three.js to Expo GL and that a `GLView` context can create a Three.js `WebGLRenderer`. This is the technically correct path for a literal 3D chessboard in a native Expo build, but it adds native graphics dependencies and requires a development build rather than relying only on Expo Go. For the current web preview, a graceful 2D fallback should remain available.

## Decision

Implement chess rules with chess.js first. Implement the visual 3D layer behind a platform-aware component using `GLView`/Three.js for native builds and a stable visual fallback for web preview. Do not describe a perspective-styled 2D board as literal 3D.

## Stockfish engine research

Sources:
- https://www.npmjs.com/package/stockfish
- https://github.com/nmrugg/stockfish.js

The current npm package is Stockfish.js 18.0.8 and is GPL-3.0. The project provides a lite single-threaded WASM build of approximately 7MB, recommended for most applications because it is fast and avoids the complexity of cross-origin isolation; the full multi-threaded build is over 100MB and requires appropriate CORS headers. The project exposes a UCI interface and is a raw engine, so the app still needs to connect it to chess.js and render the resulting move.

## Decision for this phase

Do not embed the full Stockfish binary into the Expo bundle immediately. It adds a large binary, WASM/native compatibility work, and GPL compliance obligations. Use chess.js now as the authoritative rules engine and make the local game engine-ready. A later phase can add Stockfish 18 lite single-threaded behind a native/web capability check and include the required GPL notices.

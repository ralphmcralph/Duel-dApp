# ⚔️ Commit-Reveal Duel System – Modular Battle Protocol in Solidity

![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue?style=flat&logo=solidity)
![License](https://img.shields.io/badge/License-GPL--3.0--only-green?style=flat)
![Pattern](https://img.shields.io/badge/Pattern-Commit--Reveal-orange?style=flat)

## 📌 Description

This repository implements a modular smart contract system in Solidity to manage ETH-based PvP Rock–Paper–Scissors duels using the **commit-reveal** pattern for secure and fair decision-making:

- **`DuelManager.sol`**: handles duel creation, player payments, and ETH transfers.
- **`DuelResolver.sol`**: commit-reveal logic for determining duel outcomes.
- **`interfaces/IDuelResolver.sol`**: interface used by `DuelManager` to remain agnostic to resolution logic.
- **`mocks/`**: test-friendly resolver implementations for simulating edge cases.

The architecture ensures:
- Game fairness via cryptographic commitments
- Proper separation of funds and logic
- Extensibility for alternative resolvers (DAO, randomness, etc.)

---

## 📁 Repository Structure

```
├── interfaces/
│   └── IDuelResolver.sol          # Interface expected by the DuelManager
├── mocks/
│   ├── MockResolverAlwaysDraw.sol # Always returns a draw
│   └── MockResolverAlwaysWin.sol  # Always returns a fixed winner
├── DuelManager.sol                # Main controller of duels and payouts
├── DuelResolver.sol               # Commit-reveal implementation
```

---

## 🧱 Components

### `IDuelResolver.sol`

Defines the expected interface for any resolver:

```solidity
interface IDuelResolver {
    function commitMove(uint256 duelId, bytes32 hash) external;
    function revealMove(uint256 duelId, string calldata move, string calldata salt) external;
    function resolveDuel(uint256 duelId) external view returns (address winner);
    function getPlayers(uint256 duelId) external view returns (address[2] memory);
    function hasRevealed(uint256 duelId, address player) external view returns (bool);
    function firstRevealTimestamp(uint256 duelId) external view returns (uint256);
    function registerPlayers(uint256 duelId, address p1, address p2) external;
}
```

---

### `DuelManager.sol`

Handles:

- Duel lifecycle and player payments
- Linking players with the resolver
- Calls `resolveDuel()` or `claimVictoryIfTimeout()` based on game state

```solidity
function createDuel(address opponent) external payable returns (uint256 duelId);
function acceptDuel(uint256 duelId) external payable;
function declareWinner(uint256 duelId) external;
function claimVictoryIfTimeout(uint256 duelId) external;
```

---

### `DuelResolver.sol`

Implements commit-reveal resolution logic:

```solidity
function commitMove(uint256 duelId, bytes32 hash) external;
function revealMove(uint256 duelId, string calldata move, string calldata salt) external;
function resolveDuel(uint256 duelId) external view returns (address winner);
function registerPlayers(uint256 duelId, address p1, address p2) external;
```

Includes `firstRevealTimestamp` to support timeout-based resolution.

---

## ⏱️ Timeout Handling

- A constant `REVEAL_TIMEOUT = 10 minutes` is enforced after first reveal.
- If only one player reveals → that player can claim victory.
- If neither reveals → duel results in a draw and refunds both players.

---

## 🛠️ Requirements

- Solidity `^0.8.24`
- Works in [Remix](https://remix.ethereum.org/), [Hardhat](https://hardhat.org/), or [Foundry](https://book.getfoundry.sh/)

---

## 🚀 Deployment & Usage

### 1. Deploy `DuelManager` with dummy resolver address

```solidity
DuelManager manager = new DuelManager(msg.sender, address(0));
```

### 2. Deploy `DuelResolver`, passing manager’s address

```solidity
DuelResolver resolver = new DuelResolver(address(manager));
```

### 3. Link both via `setResolver(...)`

```solidity
manager.setResolver(address(resolver));
```

### 4. Create and accept duel

```solidity
manager.createDuel(opponent);   // Player1 creates
manager.acceptDuel(duelId);     // Player2 accepts
```


---

### 🔐 Commit Hash Generation (Important!)

To commit your move securely, generate a keccak256 hash using:

```solidity
keccak256(abi.encodePacked("rock", "mySecretSalt"));
```

In JavaScript / Remix console:

```js
const { keccak256, solidityPack } = ethers.utils;

const move = "rock";          // "rock", "paper", or "scissors"
const salt = "mySecretSalt";  // A unique string per game

const packed = solidityPack(["string", "string"], [move, salt]);
const hash = keccak256(packed);
```

✅ Make sure you use **exact lowercase** for moves.  
❌ Do **not** include quotes or extra spaces inside the string.

Then call:

```solidity
resolver.commitMove(duelId, hash);
```

Later, when revealing:

```solidity
resolver.revealMove(duelId, "rock", "mySecretSalt");
```


### 5. Players commit and reveal

```solidity
resolver.commitMove(duelId, keccak256(...));
resolver.revealMove(duelId, "rock", "mysalt");
```

### 6. Resolve duel

- If both players reveal → arbiter calls:

```solidity
manager.declareWinner(duelId);
```

- If only one reveals after timeout → anyone calls:

```solidity
manager.claimVictoryIfTimeout(duelId);
```

---

## 📄 License

Licensed under the **GNU General Public License v3.0** – see the [`LICENSE`](./LICENSE) file.

---

## 📬 Contact

Open an issue or PR for improvements, questions or feedback. Contributions welcome!
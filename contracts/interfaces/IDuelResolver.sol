// License
// SPDX-License-Identifier: GPL-3.0

// Solidity version
pragma solidity 0.8.24;

/// @notice Interface for a resolver contract that decides the winner of a duel

interface IDuelResolver {
    function firstRevealTimestamp(uint256 duelId) external view returns (uint256);
    function registerPlayers(uint256 duelId, address p1, address p2) external;
    function getPlayers(uint256 duelId) external view returns (address[2] memory);
    function hasRevealed(uint256 duelId, address player) external view returns (bool);
    function commitMove(uint256 duelId, bytes32 hash) external;
    function revealMove(uint256 duelId, string calldata move, string calldata salt) external;
    function resolveDuel(uint256 duelId) external view returns (address winner);
}
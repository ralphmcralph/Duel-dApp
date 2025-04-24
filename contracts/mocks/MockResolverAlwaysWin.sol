// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../interfaces/IDuelResolver.sol";

contract MockResolverAlwaysWin is IDuelResolver {
    address public fixedWinner;

    constructor(address winner_) {
        fixedWinner = winner_;
    }

    function resolveDuel(uint256) external view override returns (address) {
        return fixedWinner;
    }

    // Dummy stubs
    function commitMove(uint256, bytes32) external override {}
    function revealMove(uint256, string calldata, string calldata) external override {}
    function registerPlayers(uint256, address, address) external override {}
    function getPlayers(uint256) external view override returns (address[2] memory) {
        return [fixedWinner, address(0)];
    }
    function hasRevealed(uint256, address) external pure override returns (bool) {
        return true;
    }
    function firstRevealTimestamp(uint256) external view override returns (uint256) {
        return block.timestamp;
    }
}

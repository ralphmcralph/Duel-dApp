// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "../interfaces/IDuelResolver.sol";

contract MockResolverAlwaysDraw is IDuelResolver {
    function commitMove(uint256, bytes32) external override {}
    function revealMove(uint256, string calldata, string calldata) external override {}
    function resolveDuel(uint256) external pure override returns (address) {
        return address(0); // Always draw
    }

    function getPlayers(uint256) external pure override returns (address[2] memory) {
        return [address(0), address(0)];
    }

    function hasRevealed(uint256, address) external pure override returns (bool) {
        return true;
    }

    function firstRevealTimestamp(uint256) external view override returns (uint256) {
        return block.timestamp;
    }

    function registerPlayers(uint256, address, address) external override {}
}

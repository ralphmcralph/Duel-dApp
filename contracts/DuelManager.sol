// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "./utils/Errors.sol";
import "./interfaces/IDuelResolver.sol";

contract DuelManager {
    struct Duel {
        address player1;
        address player2;
        uint256 betAmount;
        bool player1Paid;
        bool player2Paid;
        bool completed;
        address winner;
    }

    mapping (uint256 => Duel) public duels;
    uint256 public duelCounter;
    address public immutable arbiter;
    uint256 public constant REVEAL_TIMEOUT = 10 minutes;

    IDuelResolver public resolver;

    constructor(address arbiter_, address resolver_) {
        arbiter = arbiter_;
        resolver = IDuelResolver(resolver_);
    }

    function setResolver(address newResolver) external {
        require(address(resolver) == address(0), "Already set");
        resolver = IDuelResolver(newResolver);
    }


    receive() external payable {
        revert("Use createDuel or acceptDuel");
    }

    fallback() external payable {
        revert("Invalid function call");
    }

    event DuelCreated(
        uint256 indexed duelId,
        address indexed player1,
        address indexed player2,
        uint256 betAmount
    );

    event DuelAccepted(
        uint256 indexed duelId,
        address indexed player2
    );

    event DuelResolved(
        uint256 indexed duelId,
        address indexed winner,
        uint256 prize
    );

    // Create Duel
    function createDuel(address opponent) external payable returns (uint256 duelId) {
        if (msg.value == 0) revert NotEnoughETH();
        if (msg.sender == opponent) revert InvalidPlayer();

        duelId == duelCounter++;

        duels[duelId] = Duel({
            player1: msg.sender,
            player2: opponent,
            betAmount: msg.value,
            player1Paid: true,
            player2Paid: false,
            completed: false,
            winner: address(0)
        });

        emit DuelCreated(duelId, msg.sender, opponent, msg.value);
    }

    function acceptDuel(uint256 duelId) external payable {
        Duel storage duel = duels[duelId];

        if(msg.sender != duel.player2) revert InvalidPlayer();
        if(duel.player2Paid) revert DuelAlreadyResolved();
        if(msg.value != duel.betAmount) revert NotEnoughETH();

        duel.player2Paid = true;

        resolver.registerPlayers(duelId, duel.player1, duel.player2);

        emit DuelAccepted(duelId, msg.sender);
    }

    function declareWinner(uint256 duelId) external {
        require(msg.sender == arbiter, "Only arbiter");
        Duel storage duel = duels[duelId];
        require(!duel.completed, "Already resolved");
        require(duel.player1Paid && duel.player2Paid, "Not ready");

        duel.winner = resolver.resolveDuel(duelId);
        duel.completed = true;

        if (duel.winner == address(0) && duel.completed) {
            payable(duel.player1).transfer(duel.betAmount);
            payable(duel.player2).transfer(duel.betAmount);
        } else {
            payable(duel.winner).transfer(duel.betAmount * 2);
        }
    }

    function claimVictoryIfTimeout(uint256 duelId) external {
        Duel storage duel = duels[duelId];
        if (duel.completed) revert("Already resolved");

        address[2] memory players = resolver.getPlayers(duelId);
        bool p1Revealed = resolver.hasRevealed(duelId, players[0]);
        bool p2Revealed = resolver.hasRevealed(duelId, players[1]);

        uint256 t = resolver.firstRevealTimestamp(duelId);
        require(t > 0 && block.timestamp > t + REVEAL_TIMEOUT, "Timeout not reached");

        duel.completed = true;

        if (p1Revealed && !p2Revealed) {
            duel.winner = players[0];
            payable(players[0]).transfer(duel.betAmount * 2);
        } else if (p2Revealed && !p1Revealed) {
            duel.winner = players[1];
            payable(players[1]).transfer(duel.betAmount * 2);
        } else {
            // Seguridad extra por si ambos no revelaron
            payable(players[0]).transfer(duel.betAmount);
            payable(players[1]).transfer(duel.betAmount);
        }
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

contract DuelResolver{
    
    enum Move { None, Rock, Paper, Scissors }

    struct Commit {
        bytes32 hash;
        bool revealed;
        Move move;
    }

    address public immutable manager;

    mapping(uint256 => address[2]) public duelPlayers;
    mapping(uint256 => mapping(address => Commit)) public duelCommits;
    mapping(uint256 => uint256) public firstRevealTimestamp;

    error AlreadyCommitted();
    error AlreadyRevealed();
    error InvalidCommit();
    error NotRegisteredPlayer();
    error NotBothRevealed();
    error InvalidMove();
    error AlreadyRegistered();

    modifier onlyManager() {
        if (msg.sender != manager) revert NotRegisteredPlayer();
        _;
    }

    event MoveCommitted(uint256 indexed duelId, address indexed player);
    event MoveRevealed(uint256 indexed duelId, address indexed player, Move move);

    constructor(address manager_) {
        manager = manager_;
    }

    function registerPlayers(uint256 duelId, address p1, address p2) external onlyManager {
        if (duelPlayers[duelId][0] != address(0)) revert AlreadyRegistered();
        duelPlayers[duelId] = [p1, p2];
    }

    function commitMove(uint256 duelId, bytes32 hash) external {
        address[2] memory players = duelPlayers[duelId];
        if (msg.sender != players[0] && msg.sender != players[1]) revert NotRegisteredPlayer();
        if (duelCommits[duelId][msg.sender].hash != 0) revert AlreadyCommitted();

        duelCommits[duelId][msg.sender] = Commit({
            hash: hash,
            revealed: false,
            move: Move.None
        });

        emit MoveCommitted(duelId, msg.sender);
    }

    function revealMove(uint256 duelId, string calldata move, string calldata salt) external {
        address[2] memory players = duelPlayers[duelId];
        if (msg.sender != players[0] && msg.sender != players[1]) revert NotRegisteredPlayer();

        Commit storage commit = duelCommits[duelId][msg.sender];
        if (commit.revealed) revert AlreadyRevealed();

        bytes32 recomputed = keccak256(abi.encodePacked(move, salt));
        if (recomputed != commit.hash) revert InvalidCommit();

        Move parsed = _parseMove(move);

        commit.revealed = true;
        commit.move = parsed;

        if (firstRevealTimestamp[duelId] == 0) {
            firstRevealTimestamp[duelId] = block.timestamp;
        }


        emit MoveRevealed(duelId, msg.sender, parsed);
    }

    function resolveDuel(uint256 duelId) external view returns (address winner) {
        address[2] memory players = duelPlayers[duelId];
        Commit memory c1 = duelCommits[duelId][players[0]];
        Commit memory c2 = duelCommits[duelId][players[1]];

        if(!c1.revealed || !c2.revealed) revert NotBothRevealed();

        Move m1 = c1.move;
        Move m2 = c2.move;

        if (m1 == m2) return address(0); // Draw

        if (
            (m1 == Move.Rock && m2 == Move.Scissors) ||
            (m1 == Move.Paper && m2 == Move.Rock) ||
            (m1 == Move.Scissors && m2 == Move.Paper)
        ) return players[0];
        else return players[1];
    }

    function hasRevealed(uint256 duelId, address player) external view returns (bool) {
        return duelCommits[duelId][player].revealed;
    }

    function getPlayers(uint256 duelId) external view returns (address[2] memory) {
        return duelPlayers[duelId];
    }


    function _parseMove(string memory str) internal pure returns (Move m) {
        bytes32 h = keccak256(bytes(str));
        if (h == keccak256("rock"))     return Move.Rock;
        if (h == keccak256("paper"))    return Move.Paper;
        if (h == keccak256("scissors")) return Move.Scissors;
        revert InvalidMove();
    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {OutcomeToken} from "./OutcomeToken.sol";

contract PredictionMarket is Initializable {
    using Math for uint256;
    struct Market {
        bool resolved; // True if the market has been resolved and payouts can be settled.
        IERC20 outcome1Token; // ERC20 token representing the value of the first outcome.
        IERC20 outcome2Token; // ERC20 token representing the value of the second outcome.
        bytes outcome1; // Short name of the first outcome.
        bytes outcome2; // Short name of the second outcome.
        bytes description; // Description of the market.
        MarketStatus status;
    }
    struct Result {
        bytes32 marketId;
        Outcomes winner;
        Outcomes loser;
    }
    enum Outcomes {
        Outcome1,
        Outcome2
    }
    enum MarketStatus {
        Open,
        Resolved
    }

    event MarketInitialized(
        bytes32 indexed marketId,
        bytes description,
        bytes outcome1,
        bytes outcome2,
        address outcome1Token,
        address outcome2Token
    );

    Result public result;

    address public oracle;

    bytes32 public initializedMarketId;

    mapping(bytes32 => Market) public markets; // Maps marketId to Market struct.
    // Maps user address to outcome to uint256.
    // track balances of each user for each outcome
    mapping(address => mapping(Outcomes => uint256)) public balances;

    // track total balances of each outcome
    mapping(Outcomes => uint256) public totalBalances;

    // hypothetically, contract should be deployed for each market by a factory contract
    function initialize(
        address _oracle,
        string memory description,
        string memory outcome1,
        string memory outcome2
    ) public initializer returns (bytes32 marketId) {
        oracle = _oracle;
        marketId = InitializeMarket(description, outcome1, outcome2);
        initializedMarketId = marketId;
        return marketId;
    }

    function InitializeMarket(
        string memory description,
        string memory outcome1,
        string memory outcome2
    ) internal returns (bytes32 marketId) {
        require(bytes(outcome1).length > 0, "Empty first outcome");
        require(bytes(outcome2).length > 0, "Empty second outcome");
        require(
            keccak256(bytes(outcome1)) != keccak256(bytes(outcome2)),
            "Outcomes are the same"
        );
        require(bytes(description).length > 0, "Empty description");
        marketId = keccak256(abi.encode(block.number, description));
        require(
            markets[marketId].outcome1Token == OutcomeToken(address(0)),
            "Market already exists"
        );
        OutcomeToken outcome1Token = new OutcomeToken(
            string(abi.encodePacked(outcome1, " Token")),
            "OT1"
        );
        OutcomeToken outcome2Token = new OutcomeToken(
            string(abi.encodePacked(outcome2, " Token")),
            "OT2"
        );
        markets[marketId] = Market({
            resolved: false,
            outcome1Token: outcome1Token,
            outcome2Token: outcome2Token,
            outcome1: bytes(outcome1),
            outcome2: bytes(outcome2),
            description: bytes(description),
            status: MarketStatus.Open
        });
        emit MarketInitialized(
            marketId,
            bytes(description),
            bytes(outcome1),
            bytes(outcome2),
            address(outcome1Token),
            address(outcome2Token)
        );
    }

    function vote(bytes32 _marketId, Outcomes _outcome) external payable {
        require(
            markets[_marketId].status == MarketStatus.Open,
            "Market is not open"
        );
        require(msg.value > 0, "Must send ether to vote");

        uint sqrtVote = Math.sqrt(msg.value);
        if (_outcome == Outcomes.Outcome1) {
            balances[msg.sender][Outcomes.Outcome1] += sqrtVote;
            totalBalances[Outcomes.Outcome1] += msg.value;
        } else {
            balances[msg.sender][Outcomes.Outcome2] += sqrtVote;
            totalBalances[Outcomes.Outcome2] += msg.value;
        }
    }

    function withdraw(bytes32 _marketId) external {
        require(
            markets[_marketId].status == MarketStatus.Resolved,
            "Market is not resolved"
        );
        require(
            balances[msg.sender][result.winner] > 0,
            "No balance to withdraw"
        );
        uint256 votedBalance = balances[msg.sender][result.winner];

        uint256 userOutcome = votedBalance +
            (totalBalances[result.loser] * votedBalance) /
            totalBalances[result.winner];

        balances[msg.sender][Outcomes.Outcome1] = 0;
        balances[msg.sender][Outcomes.Outcome2] = 0;
        (bool success, ) = msg.sender.call{value: userOutcome}("");
        require(success, "Transfer failed.");
    }

    function resolveMarket(Outcomes _winner, Outcomes _loser) external {
        require(msg.sender == oracle, "Only oracle can resolve market");
        require(
            _winner != _loser,
            "Winner and loser outcomes must be different"
        );
        require(
            markets[result.marketId].status == MarketStatus.Open,
            "Market is not open"
        );
        result.winner = _winner;
        result.loser = _loser;
        markets[result.marketId].status = MarketStatus.Resolved;
    }

    function getMarket(bytes32 marketId) public view returns (Market memory) {
        return markets[marketId];
    }

    function getMarketStatus(
        bytes32 marketId
    ) public view returns (MarketStatus) {
        return markets[marketId].status;
    }

    function getInitialMarketId() public view returns (bytes32) {
        return initializedMarketId;
    }

    function getOracle() public view returns (address) {
        return oracle;
    }

    function getMarketResult() public view returns (Result memory) {
        return result;
    }

    function getMarketBalances(
        address user
    ) public view returns (uint256, uint256) {
        return (
            balances[user][Outcomes.Outcome1],
            balances[user][Outcomes.Outcome2]
        );
    }

    function getTotalBalances() public view returns (uint256, uint256) {
        return (
            totalBalances[Outcomes.Outcome1],
            totalBalances[Outcomes.Outcome2]
        );
    }
}

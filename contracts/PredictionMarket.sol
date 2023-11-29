// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {OutcomeToken} from "./OutcomeToken.sol";

contract PredictionMarket is Initializable {
    struct Market {
        bool resolved; // True if the market has been resolved and payouts can be settled.
        IERC20 outcome1Token; // ERC20 token representing the value of the first outcome.
        IERC20 outcome2Token; // ERC20 token representing the value of the second outcome.
        bytes outcome1; // Short name of the first outcome.
        bytes outcome2; // Short name of the second outcome.
        bytes description; // Description of the market.
        MarketStatus status;
    }
    enum MarketStatus {
        Open,
        Resolved
    }
		
    struct Result {
        bytes32 marketId;
        bytes outcome;
    }
    event MarketInitialized(
        bytes32 indexed marketId,
        bytes description,
        bytes outcome1,
        bytes outcome2,
        address outcome1Token,
        address outcome2Token
    );
    mapping(bytes32 => Market) public markets; // Maps marketId to Market struct.
    mapping(bytes32 => Result) public results; // Maps marketId to Result struct.

    function Initialize() public initializer {
        console.log("contract initialized");
    }

    function InitializeMarket(
        string memory description,
        string memory outcome1,
        string memory outcome2
    ) public payable returns (bytes32 marketId) {
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

    function vote() external payable {}

    function withdraw() external {}

    function resolveMarket() external {}

    function getMarket(bytes32 marketId) public view returns (Market memory) {
        return markets[marketId];
    }
}

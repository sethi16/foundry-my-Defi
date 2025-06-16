// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
contract MockV3Aggregator is AggregatorV3Interface {
    uint8 public override decimals;
    int256 public latestAnswer;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        latestAnswer = _initialAnswer;
    }

    function latestRoundData() external view override returns (
        uint80, int256, uint256, uint256, uint80
    ) {
        return (0, latestAnswer, 0, 0, 0);
    }

    // Stub the unused interface methods
    function description() external pure override returns (string memory) {
        return "MockV3Aggregator";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80) external view override returns (
        uint80, int256, uint256, uint256, uint80
    ) {
        return (0, latestAnswer, 0, 0, 0);
    }
}
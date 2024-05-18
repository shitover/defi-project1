//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library OracleLib {
    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed) public view returns (uint80, int256, uint256, uint80) {


        error OracleLib__StalePrice();

        uint256 private constant TIMEOUT = 3 hours;

        function staleCheckLatestRoundData(AggregatorV3Interface priceFeed) public view returns (uint80, int256, uint256, uint80) {
            (uint80 roundId, int256 answer, uint256 startedAt, uint80 updateAt, uint80 answeredInRound) = priceFeed.latestRoundData();
            
            uint256 secondSince =  block.timestamp - updateAt;
            if(secondsSince > TIMEOUT) {
                revert OracleLib__StalePrice();

                return (roundId, answer, startedAt, updateAt, answeredInRound); 
            }
        }

    }
}
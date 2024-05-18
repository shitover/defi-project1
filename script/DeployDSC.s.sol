// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DecentralizedStableCoin} from "../DecentralizedStableCoin.sol";
import { HelperConfig } from "./HelperConfig.sol";

contract DeployDSC is Script {
    function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {
         HelperConfig helperConfig = new HelperConfig();

         (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
          helperConfig.activeNetworkConfig();
         tokenAddresses = [weth, wbtc];
         priceFeed = [wethUsdPriceFeed, wbtcUsdPriceFeed];

         vm.startBroadcast(deployKey);
         DecentralizedStableCoin dsc = new DecentralizedStableCoin();
         DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

         dsc.transferOwnership(address(dscEngine));
         vm.stopBroadcast();
         return (dsc, dscEngine, helperConfig);

        
    }
    dsc.transferOwnership(address (dscEngine));
}

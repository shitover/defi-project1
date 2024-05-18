//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { MockV3Aggregator } from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {

    MockV3Aggregator public ethUsdPriceFeed;

    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;
    uint256 public timeMintIsCalled;
    address[] public userWithCollateralDeposited;

    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;

        ethUsdPriceFeed = MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(weth)));

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    function depositCollateral(uint256 collateralSeed, uint256 amoutCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
        dsce.depositCollateral(collateral, amountCollateral);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);
        dsce.depositCollateral(address(collateral), amountCollateral);

        vm.stopPrank();
        userWithCollateralDeposited.push(msg.sender);
    }

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collaterlSeed % 2 == 0) {
            return weth;
        }

        return wbtc;
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateral = dscEngine.getCollateralBalanceOfUser(msg.sender, address(collateral));

        amountCollateral = bound(amountCollateral, 0, maxCollateral);
        if (amountCollateral == 0) {
            return;
        }
        dscEngine.redeemCollateral(address(collateral), amountCollateral);
    }

    function mintDsc(uint256 amount, uint256 addrressSeed) public {
        if(userWithDepositedCollateral.length == 0) {
            return;
        }
        address sender = userWithDepositedCollateral[addrressSeed % userWithDepositedCollateral.length];
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(msg.sender);

        int256 maxDscMintedInt = (int256(collateralValueInUsd) / 2) - int256(dsc.totalDscMinted());
        if (maxDscMintedInt < 0) {
            return;
        }

        amount = bond(amount, 0, uint256(maxDscMintedInt));
        if (amount == 0) {
            return;
        }

        vm.startPrank();
        dsce.mintDsc(amount);
        vm.stopPrank();
        // timesMintIsCalled++;
    }

    function invariant_gettersShouldNotRevert() public view{

        dsce.getLiquidationBonus();
        dsce.getPrecision();
    }

    function updateUpdateCollateralPrice(uint96 newPrice) public {
        int256 newPriceInt = int256(uint256(newPrice));
        ethUsdPriceFeed.updateAnswer(newPriceInt);
    }
}

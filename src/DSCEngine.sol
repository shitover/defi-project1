// SPDX-License-ıdentifier: MIT

pragma solidity ^0.8.20;

import { ReentrancyGuard} from  "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DecentralizedStableCoin } from "./DecentralizedStableCoin.sol";
import {OracleLib} from "./libraries/OracleLib.sol";


contract DSCEngine is ReentrancyGuard {

    using OracleLib for AggregatorV3Interface;

      error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenNotAllowed(address token);
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactorValue);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    DecentralizedStableCoin private i_dsc;
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_priceFeed;

    mapping(address collateralToken => address priceFeed) private s_priceFeed;

    mapping(address => uint256 amount) private s_DSCMinted;


    constructor(address[] memory tokenAddresses, address[] memory priceFeed, address dscAddress) {
        if (tokenAddresses.length != priceFeed.length)
        revert("DSCEngine__TokenAdderessAndPriceFeedAddressDontMatch");

    
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
    s_priceFeed[tokenAddresses[i]] = priceFeed[i];
    s_collateralToken.push(tokenAddresses[i]);
}
i_dsc = DecentralizedStableCoin(dscAddress);

}

modifier moreThanZero(uint256 _amount) {
        if(_amount == 0) {
            revert("DSCEngine_NeedsMoreThanZero");
        }
        _;
        
}
        modifier isAllowedToken(address token) {
            if (s_priceFeeds[token] == address(0)) {
                revert("DSCEngine__NotAllowedToken");
            }

            _;
        }
      


    function depositCollateralandMintDSC(address tokenCollateralAddress, uint256 amountCollateral) external {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDepozited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert("DSCEngine__TransferFromFailed");
        }
        // deposit collateral
        // mint DSC
    }

    function depositCollateral (address tokenCollateralAddress, uint256 amountCollateral)  public moreThanZero(amountCollateral) nonReentrant isAllowedToken(tokenCollateralAddress) {
        s_collateralDeposited[msg.sender] [tokenCollateralAddress] += amountCollateral;
        emit CollateralDepozited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);    
        if (!success) {
            revert DSCEngine__TransferFailed();
            
        }
        // deposit 
    }

event CollateralRedeemed(address indexed user, address indexed tokenCollateralAddress, uint256 amountCollateral);


      function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        moreThanZero(amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
        revertIfHealthFactorIsBroken(msg.sender);
    }
    
  

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral) external moreThanZero(amountCollateral)  {

        // redeem DSC 

        _burnDsc(amountDscToBurn, msg.sender, msg.sender);
        _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
     
    } 
    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address from,
        address to
    )
        private
    {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }


    function mintDSC(uint256 amountDSCToMint) public moreThanZero(amountDSCToMint)  nonReentrant() {
        // mint DSC
        s_DSCMinted[msg.sender]  += amountDSCToMint;
        revertIfHealthFactorIsBroken(msg.sender);
        bool  minted = i_dsc.mint(msg.sender, amountDSCToMint);

        if (minted != true) {
            revert DSCEngine__MintFailed();
        }
    }  

    function burnDsc(uint256 amount) external moreThanZero(amount) {
        _burnDSC(amount, msg.sender, msg.sender);
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function _burnDSC(uint256 amoutDSCToken, address onBehalfOf, address dscFrom) private {
        s_DSCMinted[onBehalfOf] -= amountDscToBurn;

        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);

        if(!success) {
            revert DSCEngine__TransferFailed();
        } 
        i_dsc.burn(amountDscToBurn);

    } 
    event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, address token, uint256 amount);

        uint256 private constant LIQUIDATION_BONUS = 10; 

        function liquidate(address collateral, address user, uint256 debtToCover) external moreThanZero(debtToCover) nonReentrant {
            uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / 100;
            uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        } 

   

      function liquidate(
        address collateral,
        address user,
        uint256 debtToCover
    )
        external
        moreThanZero(debtToCover)
        nonReentrant
    {
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        _redeemCollateral(collateral, tokenAmountFromDebtCovered + bonusCollateral, user, msg.sender);
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        revertIfHealthFactorIsBroken(msg.sender);
    }

   

      function getHealthFactor(address tokenCollateralAddress, uint256 amountCollateral) external view {



      }
          
 function _getAccountInformation(address user) private view returns (uint256 collateralValueInUsed)
{
    totalDscMinted = s_DSCMinted[user];
     collateralValueInUsed = getAccountCollateralValueInUsed(user); 

} 

function getAccountInformation(address user) extenal view returns (uint256 totalDscMinted, uint256 collateralValueInUsed) {
    return _getAccountInformation(user);

}
 function getAccountCollateralValue(address user) public view returns (uint256 collateralValue) {
    collateralValue = 0;
    for (uint256 index = 0; i < s_collateralToken.length; i++) {
        address token = s_collateralToken[index];
        uint256 amount = s_collateralDeposited[user][token];
      
        totalCollateralValueInUsd  += _getUsdValue(token, amount);
         
         return totalCollateralValueInUsd;
    } 
 }

    function _getUsdValue(address token, uint256 amount) private view returns (uint256 value) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeed[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();

        return ((uint256(price) * ADITIONAL_FEED_PRECISON) * amount) /  PRECISON;



    } 
       function getUsdValue(
        address token,
        uint256 amount // in WEI
    )
       public
        view
        returns (uint256)
    {

        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeed[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();    
        return _getUsdValue(token, amount);
    }



function updateHealthFactor() public {

    return collateralValueInUsed / totalDscMinted; 

    uint256 private constant  LIQUIDATION_THRESHOLD = 50; //%200 OVERCOLLATERALIZED
    uint256 collateralAdjustedForThreshold = collateralValueInUsed * LIQUIDATION_THRESHOLD / 100;
}
 
 function _healthFactor(address user) private view returns (uint256) {
    (uint256 totalDscMinted, uint256 collateralValueInUsed) = _getAccountInformation(user);
    return _calculateHealthFactor(totalDscMinted, collateralValueInUsed);
 }

 function _calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsed) internal pure returns (uint256) {
   
    if (totalDscMinted == 0)  return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsed * LIQUIDATION_THRESHOLD) / 100;
        return (collateralAdjustedForThreshold * 1e18) / totalDscMinted;
        
 }

 function revertIfHealthFactorIsBroken(address user ) intenal view {
    uint256 userHealthFactor = _healthFactor(user);
    if (userHealthFactor < MIN_HEALTH_FACTOR) {
        revert DSCEngine__HealthFactorTooLow(userHealthFactor);
 }

 }
     function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) { 
     AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeed[token]);
     (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();

     return ((usdAmountInWei * PRECISON) / (uint256(price) * ADITIONAL_FEED_PRECISON));
 }   

    
     function calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsd) external pure returns (uint256) {

        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
     }

     function getCollateralBalanceOfUser(address user, address token) external view returns (uint256) {
        return s_collateralDeposited[user][token];
     }

}
   
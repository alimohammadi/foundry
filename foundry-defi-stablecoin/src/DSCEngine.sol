// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
// @title DSCEngine
/// @author Ali Mohammadi
/// @notice The system is designed to be a minimalistic and highly capital efficient, 
    and have the tokens maintain a 1 token == $1 peg
    this is stablecoin has the properties:
    - Exogenous Collateral: backed by assets external to the system (e.g., ETH, BTC)
    - Dollar Pegged: designed to maintain a stable value relative to the US Dollar
    - Algorithmically Stabilized: uses algorithms to adjust supply based on market conditions

   * It is similar to DAI, but DAI is crypto-collateralized and not exogenous-collateralized

   * our DSC system will be overcollateralized to ensure the stability of the peg.
   * At no point should the value of all the collateral <= the $ backed of all the DSC tokens
*/

contract DSCEngine is ReentrancyGuard {
    //////////////////////////////
    //      Errors
    //////////////////////////////
    error DSCEngine__MustBeMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();

    //////////////////////////////
    //      State Variables
    //////////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 50%
    uint256 private constant LIQUIDATION_CONSTANT = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private sPriceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private sCollacteralDeposit;
    mapping(address user => uint256 amountDscMinted) private sDscMinted;
    address[] private sCollateralTokens;

    DecentralizedStableCoin private immutable I_DSC;

    //////////////////////////////
    //      Events
    //////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    //////////////////////////////
    //      Modifiers
    //////////////////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (sPriceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    //////////////////////////////
    //      Functions
    //////////////////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddress, address dscAddress) {
        // USD Price Feeds
        if (tokenAddresses.length != priceFeedAddress.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            sPriceFeeds[tokenAddresses[i]] = priceFeedAddress[i];
            sCollateralTokens.push(tokenAddresses[i]);
        }

        I_DSC = DecentralizedStableCoin(dscAddress);
    }

    //////////////////////////////
    //      External Functions
    //////////////////////////////
    function depositCollateralAndMintDSC() external payable {}

    /*
     * @notice follows CEI
     * @param tokenCollateralAddress the address of the token to deposit as collateral
     * @param amountCollateral the amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        sCollacteralDeposit[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);

        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDSC() external {}

    function redeemCollateralExternal() external {}

    // check if the collateral value > DSC amount. => Price feeds, values
    /*
        * @notice follows CEI
        * @param amountDscToMint the amount of DSC to mint    
    */
    function mintDSC(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        sDscMinted[msg.sender] += amountDscToMint;
        // if they minted too much($150 DSC, $100 collateral(ETH)) => revert
        _revertIfHealthFactorIsBroken(msg.sender);

        bool minted = I_DSC.mint(msg.sender, amountDscToMint);

        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDSC() external {}

    // if the ETH price is $100 and we have $50 DSC and then ETH price drops to $80
    // our collateral value is now $40 but we have $50 DSC -> undercollateralized
    // so we need to liquidate some positions to ensure the system is always overcollateralized

    // If someone payes back your minted DSC, they can hava all your collateral at a discount
    function liquidate() external {}

    function getHealthFactor() external {}

    //////////////////////////////////////////////
    //    Private & Internal View Functions
    //////////////////////////////////////////////
    /*
        * Returns how close to liquidation a user is
        * If a user go bellow 1, then they can be liquidated 
    */
    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collaterallValueInUsd)
    {
        // 1. get all the collateral
        // 2. get all the dsc minted
        totalDscMinted = sDscMinted[user];

        collaterallValueInUsd = 0;
        collaterallValueInUsd = getAccountCollaterallValue(user);
    }

    /* 
        Returns how close to liquidation a user is
        If a user go bellow 1, then they can be liquidated
    */
    function _healthFactor(address user) private view returns (uint256) {
        // 1. get total DSC minted
        // 2. get total collateral value
        // 3. return collateralValue / dscMinted
        (uint256 totalDscMinted, uint256 collaterallValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collaterallValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_CONSTANT;
        // 1000ETH * 50 = 50,000 / 100 = 500

        // instead of ($150 ETH / 100 DSC = 1.5) => $150 * 50 = 7500 / 100  = 0.75 < 1
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    // 1. Check health factor(do they have enough collateral?)
    // 2. Revert if they don't have enough collateral
    // get total collateral value
    // get total DSC minted
    // compare the ratio
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);

        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    //////////////////////////////////////////////
    //    Public & External View Functions
    //////////////////////////////////////////////
    function getAccountCollaterallValue(address user) public view returns (uint256 totalCollaterallValueInUsd) {
        // loop through each collateral token, get the amount, they have deposited, and map it to
        // the price, to get the USD value

        // we have to loop through the mapping, but we can't loop through mappings in solidity
        // so we need to store the allowed tokens in an array (not implemented yet)

        for (uint256 i = 0; i < sCollateralTokens.length; i++) {
            address token = sCollateralTokens[i];
            uint256 amount = sCollacteralDeposit[user][token];

            if (amount > 0) {
                // uint256 price = getPriceOfToken(token);
                totalCollaterallValueInUsd += getUsdValue(token, amount); // assuming price is in 18 decimals
            }
        }

        return totalCollaterallValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(sPriceFeeds[token]); //get the price of token
        (, int256 price,,,) = priceFeed.latestRoundData();
        // 1 ETH = 1000$
        // The return value from CL will be 1000 * 1e8 (8 decimal places)
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION; // price * amount => (1000 * 1e8 ) * 1000 * 1e8
    }
}

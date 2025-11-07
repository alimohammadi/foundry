// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;

    address public USER = makeAddr("user");
    uint256 public constant PUBLIC_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 1000e18;

    function setUp() public {
        // Setup code for DSCEngine tests will go here
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        // ERC20Mock(weth).approve(address(engine), type(uint256).max);
    }

    /////////////////////////////////////////////
    /////////    Constructor Tests     //////////
    /////////////////////////////////////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertIfTokenLengthMismatch() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /////////////////////////////////////////////
    ////////////   Price Tests     //////////////
    /////////////////////////////////////////////
    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18; // 15 ETH * $2000/ETH = $30,000

        uint256 actualUsd = engine.getUsdValue(weth, ethAmount);

        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedEth = 0.05 ether; // $100 / $2000/ETH = 0.05 ETH
        uint256 actualEth = engine.getAmountFromUsd(weth, usdAmount);

        assertEq(expectedEth, actualEth);
    }

    /////////////////////////////////////////////
    ////////   DepositCollateral Tests    ///////
    /////////////////////////////////////////////
    function testRevertIfDepositZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), PUBLIC_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__MustBeMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertWithUnprovedCollateral() public {
        ERC20Mock ranTok = new ERC20Mock("RAN", "RAN", USER, PUBLIC_COLLATERAL);

        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        engine.depositCollateral(address(ranTok), PUBLIC_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), PUBLIC_COLLATERAL);
        engine.depositCollateral(weth, PUBLIC_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collaterallValueInUsd) = engine.getAccountInformation(USER);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = engine.getAmountFromUsd(weth, collaterallValueInUsd); //
        assertEq(totalDscMinted, expectedTotalDscMinted);
        // 10 ETH * $2000/ETH = $20,000
        assertEq(PUBLIC_COLLATERAL, expectedDepositAmount);
    }
}

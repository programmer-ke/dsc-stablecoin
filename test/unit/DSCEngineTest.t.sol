// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address weth;
    address wbtc;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(wbtc).mint(USER, STARTING_ERC20_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                               Constructor Tests
    //////////////////////////////////////////////////////////////*/
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /*//////////////////////////////////////////////////////////////
                               Price Tests
    //////////////////////////////////////////////////////////////*/

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsdAmount = 30000e18;
        uint256 actualUsdAmount = dsce.getUsdValue(weth, ethAmount);
        assertEq(expectedUsdAmount, actualUsdAmount);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(actualWeth, expectedWeth);
    }

    /*//////////////////////////////////////////////////////////////
                               Collateral Tests
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock("RAND", "RAND", USER, AMOUNT_COLLATERAL);

        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__TokenNotAllowed.selector, address(randToken)));
        dsce.depositCollateral(address(randToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 dscMinted, uint256 collateralInUsd) = dsce.getAccountInformation(USER);

        assertEq(dscMinted, 0);
        assertEq(collateralInUsd, dsce.getUsdValue(weth, AMOUNT_COLLATERAL));
    }

    /*//////////////////////////////////////////////////////////////
                           Health Factor Tests
    //////////////////////////////////////////////////////////////*/

    modifier createEngineAllowance() {
        vm.prank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        _;
    }

    function testHealthFactorIsOkayOnDepositAndMint() public createEngineAllowance {
        // deposit 10 ether
        // 1 ether = 2000 usd
        // 200% collateralization, means can mint max 10,000 usd

        vm.prank(USER);
        dsce.depositCollateralAndMintDsc(weth, 10 ether, 10_000 ether);

        uint256 healthFactor = dsce.getHealthFactor(USER);
        assertTrue(healthFactor >= dsce.getMinHealthFactor());
    }

    function testDepositAndMintCannotBreakHealthFactor() public createEngineAllowance {
        // deposit 10 ether
        // 1 ether = 2000 usd
        // 200% collateralization, means can mint max 10,000 usd
        uint256 collateralValue = dsce.getUsdValue(weth, 10 ether);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;
        uint256 expectedHF = (adjustedCollateral * 1e18) / (adjustedCollateral + 1e18);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHF));

        vm.prank(USER);
        // max possible DSC mint is 10_000
        dsce.depositCollateralAndMintDsc(weth, 10 ether, 10_001 ether);
    }

    function testHealthFactorAfterCollateralDeposit() public depositedCollateral {
        // collateral deposited but DSC not minted
        // should have good health
        uint256 healthFactor = dsce.getHealthFactor(USER);
        assertTrue(healthFactor > 1);
    }

    /*//////////////////////////////////////////////////////////////
                     New Health Factor Tests
    //////////////////////////////////////////////////////////////*/

    function testHealthFactorWithMultipleCollateralTokens() public {
        // Deposit both WETH and WBTC
        uint256 wethAmount = 5 ether;
        uint256 wbtcAmount = 1 ether;
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), wethAmount);
        ERC20Mock(wbtc).approve(address(dsce), wbtcAmount);
        dsce.depositCollateral(weth, wethAmount);
        dsce.depositCollateral(wbtc, wbtcAmount);
        vm.stopPrank();

        // Compute expected collateral value
        uint256 wethValue = dsce.getUsdValue(weth, wethAmount);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, wbtcAmount);
        uint256 totalCollateralValue = wethValue + wbtcValue;

        // Mint DSC up to 50% of adjusted collateral (threshold = 50%)
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (totalCollateralValue * liquidationThreshold) / liquidationPrecision;
        // Mint exactly adjustedCollateral (health factor = 1)
        uint256 dscToMint = adjustedCollateral;

        vm.prank(USER);
        dsce.mintDSC(dscToMint);

        uint256 healthFactor = dsce.getHealthFactor(USER);
        assertEq(healthFactor, 1e18);
    }

    function testHealthFactorEdgeCaseAtThreshold() public {
        // Deposit enough collateral so that adjusted collateral equals a specific DSC amount
        // We'll compute the exact amount needed for health factor = 1
        uint256 collateralAmount = 10 ether; // 10 WETH
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), collateralAmount);
        dsce.depositCollateral(weth, collateralAmount);
        vm.stopPrank();

        uint256 collateralValue = dsce.getUsdValue(weth, collateralAmount);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;

        // Mint exactly adjustedCollateral (health factor = 1)
        vm.prank(USER);
        dsce.mintDSC(adjustedCollateral);

        // Health factor should be >= 1e18 (due to integer division)
        uint256 healthFactor = dsce.getHealthFactor(USER);
        assertGe(healthFactor, 1e18);

        // Attempt to mint one extra wei should break health factor
        uint256 expectedHF = (adjustedCollateral * 1e18) / (adjustedCollateral + 1);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHF));
        vm.prank(USER);
        dsce.mintDSC(1);
    }

    function testHealthFactorAfterPriceDropAndLiquidation() public {
        ERC20Mock(weth).mint(USER, 20 ether); // ensure user has enough balance

        // Deposit collateral
        uint256 collateralAmount = 20 ether;
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), collateralAmount);
        dsce.depositCollateral(weth, collateralAmount);

        // Mint DSC up to only 80% of the adjusted collateral (more conservative)
        // This leaves room for price drop and liquidation to work
        uint256 collateralValue = dsce.getUsdValue(weth, collateralAmount);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;
        uint256 dscToMint = (adjustedCollateral * 8) / 10; // 80%
        dsce.mintDSC(dscToMint);
        vm.stopPrank();

        // Simulate a smaller price drop (from $2000 to $1500, 25% drop)
        address priceFeed = dsce.getPriceFeed(weth);
        MockV3Aggregator aggregator = MockV3Aggregator(priceFeed);
        aggregator.updateAnswer(1500e8);

        // Health factor should now be below 1 but not 0
        uint256 healthFactorAfterDrop = dsce.getHealthFactor(USER);
        assertLt(healthFactorAfterDrop, dsce.getMinHealthFactor());
        // Make sure it's not 0 (with these numbers it should be > 0)
        assertGt(healthFactorAfterDrop, 0);

        // Prepare liquidator
        address liquidator = makeAddr("liquidator");
        // Give liquidator some DSC to cover debt
        vm.prank(address(dsce));
        dsc.mint(liquidator, dscToMint);
        vm.startPrank(liquidator);
        dsc.approve(address(dsce), dscToMint);

        uint256 liquidatorStartingDSCBalance = dsc.balanceOf(liquidator);
        uint256 liquidatorStartingWethBalance = ERC20Mock(weth).balanceOf(liquidator);
        // Liquidate enough to improve health factor
        // With 20 ETH @ $1500: collateral = $30,000, adjusted = $15,000
        // DSC minted = $16,000 (80% of original $20,000 adjusted)
        // Health factor = 15,000 / 16,000 * 1e18 = 0.9375 * 1e18
        // Liquidate 4,000 DSC (25% of debt)
        uint256 debtToCover = dscToMint / 4;
        dsce.liquidate(weth, USER, debtToCover);
        vm.stopPrank();

        // Health factor of user should have improved
        uint256 healthFactorAfterLiquidation = dsce.getHealthFactor(USER);
        assertGt(healthFactorAfterLiquidation, healthFactorAfterDrop);

        // Liquidation bonus to liquidator from user is 10%
        // Liquidator deposits dsc to cover i.e. 4000
        // User is less 4000 DSC balance
        // User is less covered eth amount + liquidation bonus
        // Liquidator is less 4000 DSC (burnt by contract)
        // Liquidator is up covered eth amount + bonus
        uint256 liquidatorEndingDSCBalance = dsc.balanceOf(liquidator);
        uint256 liquidatorEndingWethBalance = ERC20Mock(weth).balanceOf(liquidator);

        assertEq(liquidatorStartingDSCBalance - 4000 * 1e18, liquidatorEndingDSCBalance);
        assertTrue(liquidatorStartingWethBalance < liquidatorEndingWethBalance);
    }

    /*//////////////////////////////////////////////////////////////
                          New Liquidation Tests
    //////////////////////////////////////////////////////////////*/

    function testLiquidationRevertsIfHealthFactorOk() public {
        // Setup: user deposits collateral and mints DSC, but stays above liquidation threshold
        uint256 collateralAmount = 10 ether;
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), collateralAmount);
        dsce.depositCollateral(weth, collateralAmount);
        // Mint a small amount of DSC that keeps health factor > 1
        uint256 collateralValue = dsce.getUsdValue(weth, collateralAmount);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;
        uint256 safeDscToMint = adjustedCollateral / 2; // 50% of adjusted collateral -> health factor = 2
        dsce.mintDSC(safeDscToMint);
        vm.stopPrank();

        // Verify health factor is >= MIN_HEALTH_FACTOR
        uint256 healthFactor = dsce.getHealthFactor(USER);
        assertGe(healthFactor, dsce.getMinHealthFactor());

        // Prepare liquidator with DSC
        address liquidator = makeAddr("liquidator");
        vm.prank(address(dsce));
        dsc.mint(liquidator, safeDscToMint);
        vm.startPrank(liquidator);
        dsc.approve(address(dsce), safeDscToMint);

        // Attempt liquidation should revert
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        dsce.liquidate(weth, USER, safeDscToMint);
        vm.stopPrank();
    }

    function testLiquidationRevertsIfHealthFactorNotImproved() public {
        // Create an undercollateralized position
        uint256 collateralAmount = 10 ether;
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), collateralAmount);
        dsce.depositCollateral(weth, collateralAmount);
        // Mint DSC up to adjusted collateral (health factor = 1)
        uint256 collateralValue = dsce.getUsdValue(weth, collateralAmount);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;
        dsce.mintDSC(adjustedCollateral);
        vm.stopPrank();

        // Simulate price drop to make health factor < 1
        address priceFeed = dsce.getPriceFeed(weth);
        MockV3Aggregator aggregator = MockV3Aggregator(priceFeed);
        // Drop price from $2000 to $1000 (50% drop)
        aggregator.updateAnswer(1000e8);

        uint256 healthFactorBefore = dsce.getHealthFactor(USER);
        assertLt(healthFactorBefore, dsce.getMinHealthFactor());

        // Prepare liquidator with DSC
        address liquidator = makeAddr("liquidator");
        uint256 debtToCover = adjustedCollateral / 10; // Cover 10% of debt
        vm.prank(address(dsce));
        dsc.mint(liquidator, debtToCover);
        vm.startPrank(liquidator);
        dsc.approve(address(dsce), debtToCover);

        // Attempt liquidation with a debtToCover that does NOT improve health factor
        // In this scenario, because the price drop is severe, covering a small amount may not improve health factor
        // We'll use a debtToCover that is too small to move the needle
        // The contract should revert with DSCEngine__HealthFactorNotImproved
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorNotImproved.selector);
        dsce.liquidate(weth, USER, debtToCover);
        vm.stopPrank();
    }
}


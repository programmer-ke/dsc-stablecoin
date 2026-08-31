// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Test, console, stdError} from "forge-std/Test.sol";
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
    uint256 public constant AMOUNT_COLLATERAL_WETH = 10 ether;
    uint256 public constant AMOUNT_COLLATERAL_WBTC = 1e8; // 1 WBTC with 8 decimals
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

        vm.expectRevert(
            DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector
        );
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /*//////////////////////////////////////////////////////////////
                               Price Tests
    //////////////////////////////////////////////////////////////*/

    function _testGetUsdValue(address token, uint256 amount, uint256 expectedUsd) private view {
        uint256 actualUsdAmount = dsce.getUsdValue(token, amount);
        assertEq(expectedUsd, actualUsdAmount);
    }

    function testGetUsdValueWeth() public view {
        // 15 WETH * $2000 = $30,000
        _testGetUsdValue(weth, 15e18, 30000e18);
    }

    function testGetUsdValueWbtc() public view {
        // 2 WBTC * $50,000 = $100,000
        _testGetUsdValue(wbtc, 2e8, 100000e18);
    }

    function _testGetTokenAmountFromUsd(
        address token,
        uint256 usdAmount,
        uint256 expectedTokenAmount
    ) private view {
        uint256 actualTokenAmount = dsce.getTokenAmountFromUsd(token, usdAmount);
        assertEq(actualTokenAmount, expectedTokenAmount);
    }

    function testGetTokenAmountFromUsdWeth() public view {
        // $100 / $2000 per WETH = 0.05 WETH
        _testGetTokenAmountFromUsd(weth, 100 ether, 0.05 ether);
    }

    function testGetTokenAmountFromUsdWbtc() public view {
        // $100 / $50,000 per WBTC = 0.002 WBTC (0.002 * 1e8 = 200000)
        _testGetTokenAmountFromUsd(wbtc, 100 ether, 2e5);
    }

    /*//////////////////////////////////////////////////////////////
                               Collateral Tests
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL_WETH);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock("RAND", "RAND", USER, AMOUNT_COLLATERAL_WETH, 18);

        vm.startPrank(USER);
        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__TokenNotAllowed.selector, address(randToken)
            )
        );
        dsce.depositCollateral(address(randToken), AMOUNT_COLLATERAL_WETH);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL_WETH);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL_WETH);
        vm.stopPrank();
        _;
    }

    function _testCanDepositCollateralAndGetAccountInfo(
        address token,
        uint256 amountCollateral,
        uint256 expectedUsd
    ) private {
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        vm.stopPrank();

        (uint256 dscMinted, uint256 collateralInUsd) = dsce.getAccountInformation(USER);

        assertEq(dscMinted, 0);
        assertEq(collateralInUsd, expectedUsd);
    }

    function testCanDepositWethCollateralAndGetAccountInfo() public {
        // 10 WETH * $2000 = $20,000 with 18 decimals -> 20_000e18
        _testCanDepositCollateralAndGetAccountInfo(weth, AMOUNT_COLLATERAL_WETH, 20_000 ether);
    }

    function testCanDepositWbtcCollateralAndGetAccountInfo() public {
        // 1 WBTC * $50,000 = $50,000 with 18 decimals -> 50_000e18
        _testCanDepositCollateralAndGetAccountInfo(wbtc, AMOUNT_COLLATERAL_WBTC, 50_000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                           Health Factor Tests
    //////////////////////////////////////////////////////////////*/

    modifier createEngineAllowance() {
        vm.prank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL_WETH);
        _;
    }

    function _testHealthFactorIsOkayOnDepositAndMint(
        address token,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) private {
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateralAndMintDsc(token, amountCollateral, amountDscToMint);
        vm.stopPrank();

        uint256 healthFactor = dsce.getHealthFactor(USER);
        assertTrue(healthFactor >= dsce.getMinHealthFactor());
    }

    function testHealthFactorIsOkayOnDepositAndMintWeth() public {
        // 10 WETH * $2000 = $20,000. 50% threshold = $10,000 max mint.
        _testHealthFactorIsOkayOnDepositAndMint(weth, AMOUNT_COLLATERAL_WETH, 10_000 ether);
    }

    function testHealthFactorIsOkayOnDepositAndMintWbtc() public {
        // 1 WBTC * $50,000 = $50,000. 50% threshold = $25,000 max mint.
        _testHealthFactorIsOkayOnDepositAndMint(wbtc, AMOUNT_COLLATERAL_WBTC, 25_000 ether);
    }

    function _testDepositAndMintCannotBreakHealthFactor(
        address token,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) private {
        uint256 collateralValue = dsce.getUsdValue(token, amountCollateral);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;
        uint256 expectedHF = (adjustedCollateral * 1e18) / amountDscToMint;

        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        vm.expectRevert(
            abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHF)
        );
        dsce.depositCollateralAndMintDsc(token, amountCollateral, amountDscToMint);
        vm.stopPrank();
    }

    function testDepositAndMintCannotBreakHealthFactorWeth() public {
        // 10 WETH * $2000 = $20,000. 50% threshold = $10,000 max mint.
        _testDepositAndMintCannotBreakHealthFactor(weth, AMOUNT_COLLATERAL_WETH, 10_001 ether);
    }

    function testDepositAndMintCannotBreakHealthFactorWbtc() public {
        // 1 WBTC * $50,000 = $50,000. 50% threshold = $25,000 max mint.
        _testDepositAndMintCannotBreakHealthFactor(wbtc, AMOUNT_COLLATERAL_WBTC, 25_001 ether);
    }

    function _testHealthFactorAfterCollateralDeposit(address token, uint256 amountCollateral)
        private
    {
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        vm.stopPrank();

        uint256 healthFactor = dsce.getHealthFactor(USER);
        assertTrue(healthFactor > 1);
    }

    function testHealthFactorAfterCollateralDepositWeth() public {
        _testHealthFactorAfterCollateralDeposit(weth, AMOUNT_COLLATERAL_WETH);
    }

    function testHealthFactorAfterCollateralDepositWbtc() public {
        _testHealthFactorAfterCollateralDeposit(wbtc, AMOUNT_COLLATERAL_WBTC);
    }

    /*//////////////////////////////////////////////////////////////
                     New Health Factor Tests
    //////////////////////////////////////////////////////////////*/

    function testHealthFactorWithMultipleCollateralTokens() public {
        // Deposit both WETH and WBTC
        uint256 wethAmount = 5 ether;
        uint256 wbtcAmount = 1e8; // 1 WBTC
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
        uint256 adjustedCollateral =
            (totalCollateralValue * liquidationThreshold) / liquidationPrecision;
        // Mint exactly adjustedCollateral (health factor = 1)
        uint256 dscToMint = adjustedCollateral;

        vm.prank(USER);
        dsce.mintDSC(dscToMint);

        uint256 healthFactor = dsce.getHealthFactor(USER);
        assertEq(healthFactor, 1e18);
    }

    function _testHealthFactorEdgeCaseAtThreshold(address token, uint256 amountCollateral) private {
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        vm.stopPrank();

        uint256 collateralValue = dsce.getUsdValue(token, amountCollateral);
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
        vm.expectRevert(
            abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHF)
        );
        vm.prank(USER);
        dsce.mintDSC(1);
    }

    function testHealthFactorEdgeCaseAtThresholdWeth() public {
        _testHealthFactorEdgeCaseAtThreshold(weth, AMOUNT_COLLATERAL_WETH);
    }

    function testHealthFactorEdgeCaseAtThresholdWbtc() public {
        _testHealthFactorEdgeCaseAtThreshold(wbtc, AMOUNT_COLLATERAL_WBTC);
    }

    function _testHealthFactorAfterPriceDropAndLiquidation(
        address token,
        uint256 amountCollateral,
        int256 newPrice
    ) private {
        ERC20Mock(token).mint(USER, amountCollateral); // ensure user has enough balance

        // Deposit collateral
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);

        // Mint DSC up to only 80% of the adjusted collateral (more conservative)
        // This leaves room for price drop and liquidation to work
        uint256 collateralValue = dsce.getUsdValue(token, amountCollateral);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;
        uint256 dscToMint = (adjustedCollateral * 8) / 10; // 80%
        dsce.mintDSC(dscToMint);
        vm.stopPrank();

        // Simulate a smaller price drop
        address priceFeed = dsce.getPriceFeed(token);
        MockV3Aggregator aggregator = MockV3Aggregator(priceFeed);
        aggregator.updateAnswer(newPrice);

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
        uint256 liquidatorStartingTokenBalance = ERC20Mock(token).balanceOf(liquidator);

        // Liquidate 25% of debt
        uint256 debtToCover = dscToMint / 4;
        dsce.liquidate(token, USER, debtToCover);
        vm.stopPrank();

        // Health factor of user should have improved
        uint256 healthFactorAfterLiquidation = dsce.getHealthFactor(USER);
        assertGt(healthFactorAfterLiquidation, healthFactorAfterDrop);

        // Liquidator is less debtToCover DSC (burnt by contract)
        // Liquidator is up covered token amount + bonus
        uint256 liquidatorEndingDSCBalance = dsc.balanceOf(liquidator);
        uint256 liquidatorEndingTokenBalance = ERC20Mock(token).balanceOf(liquidator);

        assertEq(liquidatorStartingDSCBalance - debtToCover, liquidatorEndingDSCBalance);
        assertTrue(liquidatorStartingTokenBalance < liquidatorEndingTokenBalance);
    }

    function testHealthFactorAfterPriceDropAndLiquidationWeth() public {
        // 20 WETH * $2000 = $40,000. 50% threshold = $20,000 adjusted. 80% mint = $16,000.
        // Drop price to $1500 -> 20 ETH @ $1500 = $30,000. Adjusted = $15,000. HF = 15,000 / 16,000 = 0.9375
        _testHealthFactorAfterPriceDropAndLiquidation(weth, 20 ether, 1500e8);
    }

    function testHealthFactorAfterPriceDropAndLiquidationWbtc() public {
        // 2 WBTC * $50,000 = $100,000. 50% threshold = $50,000 adjusted. 80% mint = $40,000.
        // Drop price to $30,000 -> 2 WBTC @ $30,000 = $60,000. Adjusted = $30,000. HF = 30,000 / 40,000 = 0.75
        _testHealthFactorAfterPriceDropAndLiquidation(wbtc, 2e8, 30000e8);
    }

    /*//////////////////////////////////////////////////////////////
                          New Liquidation Tests
    //////////////////////////////////////////////////////////////*/

    function _testLiquidationRevertsIfHealthFactorOk(address token, uint256 amountCollateral)
        private
    {
        // Setup: user deposits collateral and mints DSC, but stays above liquidation threshold
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        // Mint a small amount of DSC that keeps health factor > 1
        uint256 collateralValue = dsce.getUsdValue(token, amountCollateral);
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
        dsce.liquidate(token, USER, safeDscToMint);
        vm.stopPrank();
    }

    function testLiquidationRevertsIfHealthFactorOkWeth() public {
        _testLiquidationRevertsIfHealthFactorOk(weth, AMOUNT_COLLATERAL_WETH);
    }

    function testLiquidationRevertsIfHealthFactorOkWbtc() public {
        _testLiquidationRevertsIfHealthFactorOk(wbtc, AMOUNT_COLLATERAL_WBTC);
    }

    function _testLiquidationRevertsIfHealthFactorNotImproved(
        address token,
        uint256 amountCollateral,
        int256 newPrice
    ) private {
        // Create an undercollateralized position
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        // Mint DSC up to adjusted collateral (health factor = 1)
        uint256 collateralValue = dsce.getUsdValue(token, amountCollateral);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;
        dsce.mintDSC(adjustedCollateral);
        vm.stopPrank();

        // Simulate price drop to make health factor < 1
        address priceFeed = dsce.getPriceFeed(token);
        MockV3Aggregator aggregator = MockV3Aggregator(priceFeed);
        aggregator.updateAnswer(newPrice);

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
        // The contract should revert with DSCEngine__HealthFactorNotImproved
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorNotImproved.selector);
        dsce.liquidate(token, USER, debtToCover);
        vm.stopPrank();
    }

    function testLiquidationRevertsIfHealthFactorNotImprovedWeth() public {
        // 10 WETH * $2000 = $20,000. 50% threshold = $10,000 adjusted. Mint = $10,000.
        // Drop price to $1000 -> 10 ETH @ $1000 = $10,000. Adjusted = $5,000. HF = 0.5
        _testLiquidationRevertsIfHealthFactorNotImproved(weth, AMOUNT_COLLATERAL_WETH, 1000e8);
    }

    function testLiquidationRevertsIfHealthFactorNotImprovedWbtc() public {
        // 1 WBTC * $50,000 = $50,000. 50% threshold = $25,000 adjusted. Mint = $25,000.
        // Drop price to $20,000 -> 1 WBTC @ $20,000 = $20,000. Adjusted = $10,000. HF = 0.4
        _testLiquidationRevertsIfHealthFactorNotImproved(wbtc, AMOUNT_COLLATERAL_WBTC, 20000e8);
    }

    /*//////////////////////////////////////////////////////////////
                          New Minting & Burning Tests
    //////////////////////////////////////////////////////////////*/

    function _testMintDSCIncreasesDebt(
        address token,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) private {
        // Deposit collateral first
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        vm.stopPrank();

        // Record initial debt (should be zero)
        (uint256 initialDscMinted, uint256 initialCollateralValue) =
            dsce.getAccountInformation(USER);
        assertEq(initialDscMinted, 0);
        assertEq(initialCollateralValue, dsce.getUsdValue(token, amountCollateral));

        // Mint some DSC
        vm.prank(USER);
        dsce.mintDSC(amountDscToMint);

        // Verify debt increased
        (uint256 finalDscMinted, uint256 finalCollateralValue) = dsce.getAccountInformation(USER);
        assertGt(finalDscMinted, initialDscMinted);
        assertEq(finalCollateralValue, initialCollateralValue);
    }

    function testMintDSCIncreasesDebtWeth() public {
        _testMintDSCIncreasesDebt(weth, AMOUNT_COLLATERAL_WETH, 5000 ether);
    }

    function testMintDSCIncreasesDebtWbtc() public {
        _testMintDSCIncreasesDebt(wbtc, AMOUNT_COLLATERAL_WBTC, 5000 ether);
    }

    function _testBurnDSCDecreasesDebt(
        address token,
        uint256 amountCollateral,
        uint256 amountDscToMint,
        uint256 burnAmount
    ) private {
        // Deposit collateral and mint DSC
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        dsce.mintDSC(amountDscToMint);
        vm.stopPrank();

        // Record initial debt
        (uint256 initialDscMinted,) = dsce.getAccountInformation(USER);
        assertEq(initialDscMinted, amountDscToMint);

        // Burn a portion of the minted DSC
        // Need to approve the DSCEngine to spend USER's DSC
        vm.prank(USER);
        dsc.approve(address(dsce), burnAmount);
        vm.prank(USER);
        dsce.burnDsc(burnAmount);

        // Verify debt decreased
        (uint256 finalDscMinted,) = dsce.getAccountInformation(USER);
        assertEq(finalDscMinted, amountDscToMint - burnAmount);
    }

    function testBurnDSCDecreasesDebtWeth() public {
        _testBurnDSCDecreasesDebt(weth, AMOUNT_COLLATERAL_WETH, 5000 ether, 2000 ether);
    }

    function testBurnDSCDecreasesDebtWbtc() public {
        _testBurnDSCDecreasesDebt(wbtc, AMOUNT_COLLATERAL_WBTC, 5000 ether, 2000 ether);
    }

    function testMintDSCRevertsIfNoCollateral() public {
        // Do NOT deposit any collateral
        // Attempt to mint DSC directly
        uint256 dscToMint = 1000 ether;
        // Should revert because health factor would be broken (zero collateral)
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, 0));
        vm.prank(USER);
        dsce.mintDSC(dscToMint);
    }

    function _testBurnDSCRevertsIfHealthFactorStillBroken(
        address token,
        uint256 amountCollateral,
        int256 newPrice,
        uint256 burnAmount
    ) private {
        // Create an undercollateralized position
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        // Mint DSC up to adjusted collateral (health factor = 1)
        uint256 collateralValue = dsce.getUsdValue(token, amountCollateral);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;
        dsce.mintDSC(adjustedCollateral);
        vm.stopPrank();

        // Simulate price drop to make health factor < 1
        address priceFeed = dsce.getPriceFeed(token);
        MockV3Aggregator aggregator = MockV3Aggregator(priceFeed);
        aggregator.updateAnswer(newPrice);

        // Verify health factor is broken
        uint256 healthFactorBefore = dsce.getHealthFactor(USER);
        assertLt(healthFactorBefore, dsce.getMinHealthFactor());

        // Compute expected health factor after burning
        // Get current account information
        (uint256 currentDscMinted, uint256 currentCollateralValue) =
            dsce.getAccountInformation(USER);
        uint256 dscMintedAfterBurn = currentDscMinted - burnAmount;
        // Use the contract's calculateHealthFactor function
        uint256 healthFactorAfterBurn =
            dsce.calculateHealthFactor(dscMintedAfterBurn, currentCollateralValue);

        // Need approval
        vm.prank(USER);
        dsc.approve(address(dsce), burnAmount);
        // Should revert because health factor remains broken after burning
        // Match the exact error with computed health factor
        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__BreaksHealthFactor.selector, healthFactorAfterBurn
            )
        );
        vm.prank(USER);
        dsce.burnDsc(burnAmount);
    }

    function testBurnDSCRevertsIfHealthFactorStillBrokenWeth() public {
        _testBurnDSCRevertsIfHealthFactorStillBroken(weth, AMOUNT_COLLATERAL_WETH, 1000e8, 1 ether);
    }

    function testBurnDSCRevertsIfHealthFactorStillBrokenWbtc() public {
        _testBurnDSCRevertsIfHealthFactorStillBroken(wbtc, AMOUNT_COLLATERAL_WBTC, 20000e8, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          Deposit & Redeem Tests
    //////////////////////////////////////////////////////////////*/

    function _testRedeemCollateralRevertsIfHealthFactorBreaks(
        address token,
        uint256 amountCollateral,
        uint256 redeemAmount
    ) private {
        // Deposit collateral and mint DSC to the edge
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        // Mint DSC up to adjusted collateral (health factor = 1)
        uint256 collateralValue = dsce.getUsdValue(token, amountCollateral);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral = (collateralValue * liquidationThreshold) / liquidationPrecision;
        dsce.mintDSC(adjustedCollateral);
        vm.stopPrank();

        // Compute expected health factor after redeem
        uint256 newCollateralValue = dsce.getUsdValue(token, amountCollateral - redeemAmount);
        uint256 newAdjustedCollateral =
            (newCollateralValue * liquidationThreshold) / liquidationPrecision;
        uint256 expectedHealthFactor =
            (newAdjustedCollateral * dsce.getPrecision()) / adjustedCollateral;
        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHealthFactor
            )
        );
        vm.prank(USER);
        dsce.redeemCollateral(token, redeemAmount);
    }

    function testRedeemCollateralRevertsIfHealthFactorBreaksWeth() public {
        _testRedeemCollateralRevertsIfHealthFactorBreaks(weth, AMOUNT_COLLATERAL_WETH, 1);
    }

    function testRedeemCollateralRevertsIfHealthFactorBreaksWbtc() public {
        _testRedeemCollateralRevertsIfHealthFactorBreaks(wbtc, AMOUNT_COLLATERAL_WBTC, 1);
    }

    function _testRedeemCollateralFromEmptyBalanceReverts(address token, uint256 redeemAmount)
        private
    {
        // No deposit, attempt to redeem
        // Expect arithmetic underflow (since balance is 0)
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(USER);
        dsce.redeemCollateral(token, redeemAmount);
    }

    function testRedeemCollateralFromEmptyBalanceRevertsWeth() public {
        _testRedeemCollateralFromEmptyBalanceReverts(weth, 1 ether);
    }

    function testRedeemCollateralFromEmptyBalanceRevertsWbtc() public {
        _testRedeemCollateralFromEmptyBalanceReverts(wbtc, 1e8);
    }

    function testDepositMultipleCollateralTypesAndRedeemOne() public {
        // Deposit two types
        uint256 wethAmount = 5 ether;
        uint256 wbtcAmount = 1e8; // 1 WBTC
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), wethAmount);
        ERC20Mock(wbtc).approve(address(dsce), wbtcAmount);
        dsce.depositCollateral(weth, wethAmount);
        dsce.depositCollateral(wbtc, wbtcAmount);
        // Mint some DSC (half of allowed)
        uint256 totalCollateralValue = dsce.getAccountCollateralValue(USER);
        uint256 liquidationThreshold = dsce.getLiquidationThreshold();
        uint256 liquidationPrecision = dsce.getLiquidationPrecision();
        uint256 adjustedCollateral =
            (totalCollateralValue * liquidationThreshold) / liquidationPrecision;
        uint256 dscToMint = adjustedCollateral / 2;
        dsce.mintDSC(dscToMint);
        vm.stopPrank();

        // Record initial balances and health factor
        (uint256 initialDscMinted, uint256 initialCollateralValue) =
            dsce.getAccountInformation(USER);
        uint256 initialHealthFactor = dsce.getHealthFactor(USER);
        assertGt(initialHealthFactor, dsce.getMinHealthFactor());

        // Redeem some WETH
        uint256 redeemWeth = 1 ether;
        vm.prank(USER);
        dsce.redeemCollateral(weth, redeemWeth);

        // Verify state
        (uint256 finalDscMinted, uint256 finalCollateralValue) = dsce.getAccountInformation(USER);
        assertEq(finalDscMinted, initialDscMinted);
        uint256 expectedCollateralValueRemoved = dsce.getUsdValue(weth, redeemWeth);
        assertEq(finalCollateralValue, initialCollateralValue - expectedCollateralValueRemoved);
        // Health factor should still be safe
        uint256 finalHealthFactor = dsce.getHealthFactor(USER);
        assertGt(finalHealthFactor, dsce.getMinHealthFactor());
    }

    function _testRedeemCollateralForDscWorks(
        address token,
        uint256 amountCollateral,
        uint256 amountDscToMint,
        uint256 redeemCollateralAmount,
        uint256 burnDscAmount
    ) private {
        // Deposit collateral
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        // Mint some DSC
        dsce.mintDSC(amountDscToMint);
        vm.stopPrank();

        // Approve DSCEngine to burn DSC
        vm.prank(USER);
        dsc.approve(address(dsce), amountDscToMint);

        // Record initial state
        (uint256 initialDscMinted, uint256 initialCollateralValue) =
            dsce.getAccountInformation(USER);
        uint256 initialHealthFactor = dsce.getHealthFactor(USER);
        assertGt(initialHealthFactor, dsce.getMinHealthFactor());

        // Redeem collateral and burn DSC
        vm.prank(USER);
        dsce.redeemCollateralForDsc(token, redeemCollateralAmount, burnDscAmount);

        // Verify state
        (uint256 finalDscMinted, uint256 finalCollateralValue) = dsce.getAccountInformation(USER);
        assertEq(finalDscMinted, initialDscMinted - burnDscAmount);
        uint256 expectedCollateralValueRemoved = dsce.getUsdValue(token, redeemCollateralAmount);
        assertEq(finalCollateralValue, initialCollateralValue - expectedCollateralValueRemoved);
        // Health factor should still be safe (likely improved)
        uint256 finalHealthFactor = dsce.getHealthFactor(USER);
        assertGt(finalHealthFactor, dsce.getMinHealthFactor());
    }

    function testRedeemCollateralForDscWorksWeth() public {
        _testRedeemCollateralForDscWorks(
            weth, AMOUNT_COLLATERAL_WETH, 5000 ether, 2 ether, 1000 ether
        );
    }

    function testRedeemCollateralForDscWorksWbtc() public {
        // 0.1 WBTC = $5,000, so redeeming 0.1 WBTC and burning 1000 DSC is safe
        _testRedeemCollateralForDscWorks(wbtc, AMOUNT_COLLATERAL_WBTC, 5000 ether, 1e7, 1000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                     Token Approval & Transfer Tests
    //////////////////////////////////////////////////////////////*/

    function _testDepositCollateralRevertsWhenAllowanceInsufficient(
        address token,
        uint256 depositAmount
    ) private {
        // User has tokens but hasn't approved the engine
        vm.startPrank(USER);
        // Do NOT call approve
        // Expect ERC20 insufficient allowance revert
        vm.expectRevert();
        dsce.depositCollateral(token, depositAmount);
        vm.stopPrank();
    }

    function testDepositCollateralRevertsWhenAllowanceInsufficientWeth() public {
        _testDepositCollateralRevertsWhenAllowanceInsufficient(weth, 5 ether);
    }

    function testDepositCollateralRevertsWhenAllowanceInsufficientWbtc() public {
        _testDepositCollateralRevertsWhenAllowanceInsufficient(wbtc, 5e7); // 0.5 WBTC
    }

    function _testDepositCollateralRevertsWhenBalanceInsufficient(
        address token,
        uint256 depositAmount
    ) private {
        // User approves but doesn't have enough tokens
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), depositAmount);
        // Expect ERC20 transfer amount exceeds balance revert
        vm.expectRevert();
        dsce.depositCollateral(token, depositAmount);
        vm.stopPrank();
    }

    function testDepositCollateralRevertsWhenBalanceInsufficientWeth() public {
        // More than STARTING_ERC20_BALANCE (10 ether)
        _testDepositCollateralRevertsWhenBalanceInsufficient(weth, 20 ether);
    }

    function testDepositCollateralRevertsWhenBalanceInsufficientWbtc() public {
        // More than STARTING_ERC20_BALANCE (10 ether)
        _testDepositCollateralRevertsWhenBalanceInsufficient(wbtc, 20 ether);
    }

    function _testDepositCollateralWorksWithSufficientAllowanceAndBalance(
        address token,
        uint256 depositAmount
    ) private {
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), depositAmount);
        dsce.depositCollateral(token, depositAmount);
        vm.stopPrank();

        // Verify internal accounting
        uint256 deposited = dsce.getAccountCollateralValue(USER);
        uint256 expectedValue = dsce.getUsdValue(token, depositAmount);
        assertEq(deposited, expectedValue);
    }

    function testDepositCollateralWorksWithSufficientAllowanceAndBalanceWeth() public {
        _testDepositCollateralWorksWithSufficientAllowanceAndBalance(weth, 5 ether);
    }

    function testDepositCollateralWorksWithSufficientAllowanceAndBalanceWbtc() public {
        _testDepositCollateralWorksWithSufficientAllowanceAndBalance(wbtc, 5e7); // 0.5 WBTC
    }

    function _testBurnDscRevertsWhenAllowanceInsufficient(
        address token,
        uint256 amountCollateral,
        uint256 amountDscToMint,
        uint256 burnAmount
    ) private {
        // First deposit collateral and mint DSC
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        dsce.mintDSC(amountDscToMint);
        vm.stopPrank();

        // Try to burn without approving DSC
        vm.expectRevert();
        vm.prank(USER);
        dsce.burnDsc(burnAmount);
    }

    function testBurnDscRevertsWhenAllowanceInsufficientWeth() public {
        _testBurnDscRevertsWhenAllowanceInsufficient(
            weth, AMOUNT_COLLATERAL_WETH, 5000 ether, 1000 ether
        );
    }

    function testBurnDscRevertsWhenAllowanceInsufficientWbtc() public {
        _testBurnDscRevertsWhenAllowanceInsufficient(
            wbtc, AMOUNT_COLLATERAL_WBTC, 5000 ether, 1000 ether
        );
    }

    function _testBurnDscWorksWithSufficientAllowance(
        address token,
        uint256 amountCollateral,
        uint256 amountDscToMint,
        uint256 burnAmount
    ) private {
        // Deposit collateral and mint DSC
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        dsce.mintDSC(amountDscToMint);
        vm.stopPrank();

        // Approve DSCEngine to spend DSC
        vm.prank(USER);
        dsc.approve(address(dsce), amountDscToMint);

        // Burn some DSC
        vm.prank(USER);
        dsce.burnDsc(burnAmount);

        // Verify debt decreased
        (uint256 finalDscMinted,) = dsce.getAccountInformation(USER);
        assertEq(finalDscMinted, amountDscToMint - burnAmount);
    }

    function testBurnDscWorksWithSufficientAllowanceWeth() public {
        _testBurnDscWorksWithSufficientAllowance(
            weth, AMOUNT_COLLATERAL_WETH, 5000 ether, 2000 ether
        );
    }

    function testBurnDscWorksWithSufficientAllowanceWbtc() public {
        _testBurnDscWorksWithSufficientAllowance(
            wbtc, AMOUNT_COLLATERAL_WBTC, 5000 ether, 2000 ether
        );
    }

    function _testRedeemCollateralForDscRevertsWhenBurnAllowanceInsufficient(
        address token,
        uint256 amountCollateral,
        uint256 amountDscToMint,
        uint256 redeemAmount,
        uint256 burnAmount
    ) private {
        // Deposit collateral and mint DSC
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        dsce.mintDSC(amountDscToMint);
        vm.stopPrank();

        // Try to redeem collateral and burn DSC without approving DSC
        vm.expectRevert();
        vm.prank(USER);
        dsce.redeemCollateralForDsc(token, redeemAmount, burnAmount);
    }

    function testRedeemCollateralForDscRevertsWhenBurnAllowanceInsufficientWeth() public {
        _testRedeemCollateralForDscRevertsWhenBurnAllowanceInsufficient(
            weth, AMOUNT_COLLATERAL_WETH, 5000 ether, 2 ether, 1000 ether
        );
    }

    function testRedeemCollateralForDscRevertsWhenBurnAllowanceInsufficientWbtc() public {
        _testRedeemCollateralForDscRevertsWhenBurnAllowanceInsufficient(
            wbtc, AMOUNT_COLLATERAL_WBTC, 5000 ether, 1e7, 1000 ether
        );
    }

    function _testRedeemCollateralForDscWorksWithSufficientAllowance(
        address token,
        uint256 amountCollateral,
        uint256 amountDscToMint,
        uint256 redeemCollateralAmount,
        uint256 burnDscAmount
    ) private {
        // Deposit collateral and mint DSC
        vm.startPrank(USER);
        ERC20Mock(token).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(token, amountCollateral);
        dsce.mintDSC(amountDscToMint);
        vm.stopPrank();

        // Approve DSCEngine to burn DSC
        vm.prank(USER);
        dsc.approve(address(dsce), amountDscToMint);

        // Record initial state
        (uint256 initialDscMinted, uint256 initialCollateralValue) =
            dsce.getAccountInformation(USER);
        uint256 initialHealthFactor = dsce.getHealthFactor(USER);
        assertGt(initialHealthFactor, dsce.getMinHealthFactor());

        // Redeem collateral and burn DSC
        vm.prank(USER);
        dsce.redeemCollateralForDsc(token, redeemCollateralAmount, burnDscAmount);

        // Verify state
        (uint256 finalDscMinted, uint256 finalCollateralValue) = dsce.getAccountInformation(USER);
        assertEq(finalDscMinted, initialDscMinted - burnDscAmount);
        uint256 expectedCollateralValueRemoved = dsce.getUsdValue(token, redeemCollateralAmount);
        assertEq(finalCollateralValue, initialCollateralValue - expectedCollateralValueRemoved);
        // Health factor should still be safe
        uint256 finalHealthFactor = dsce.getHealthFactor(USER);
        assertGt(finalHealthFactor, dsce.getMinHealthFactor());
    }

    function testRedeemCollateralForDscWorksWithSufficientAllowanceWeth() public {
        _testRedeemCollateralForDscWorksWithSufficientAllowance(
            weth, AMOUNT_COLLATERAL_WETH, 5000 ether, 2 ether, 1000 ether
        );
    }

    function testRedeemCollateralForDscWorksWithSufficientAllowanceWbtc() public {
        _testRedeemCollateralForDscWorksWithSufficientAllowance(
            wbtc, AMOUNT_COLLATERAL_WBTC, 5000 ether, 1e7, 1000 ether
        );
    }
}

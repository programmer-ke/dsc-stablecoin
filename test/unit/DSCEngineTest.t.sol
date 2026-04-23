// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address weth;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
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
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, 0));

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
}


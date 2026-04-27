// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;
    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;
    uint256 public timesMintIsCalled;
    uint256 public timesRedeemIsCalled;
    address[] usersWithCollateralDeposited;

    constructor(DSCEngine _engine, DecentralizedStableCoin _dsc) {
        dsce = _engine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);

        dsce.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();

        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral, uint256 addressSeed) public {
        if (usersWithCollateralDeposited.length == 0) {
            return;
        }

        uint256 addressIndex = addressSeed % usersWithCollateralDeposited.length;
        address sender = usersWithCollateralDeposited[addressIndex];

        ERC20Mock collateral = _getCollateralSeed(collateralSeed);

        (uint256 totalMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(sender);
        uint256 maxUsdValueToRedeem = collateralValueInUsd - (totalMinted * 2);

        if (maxUsdValueToRedeem <= 0) {
            return;
        }

        uint256 maxCollateralToRedeem = dsce.getTokenAmountFromUsd(address(collateral), maxUsdValueToRedeem);
        uint256 collateralBalanceOfUser = dsce.getCollateralBalanceOfUser(address(collateral), sender);
        maxCollateralToRedeem =
            collateralBalanceOfUser < maxCollateralToRedeem ? collateralBalanceOfUser : maxCollateralToRedeem;

        amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);

        if (amountCollateral == 0) {
            return;
        }

        vm.prank(sender);
        dsce.redeemCollateral(address(collateral), amountCollateral);

        timesRedeemIsCalled++;
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        if (usersWithCollateralDeposited.length == 0) {
            return;
        }
        uint256 addressIndex = addressSeed % usersWithCollateralDeposited.length;
        address sender = usersWithCollateralDeposited[addressIndex];

        (uint256 totalMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(sender);

        uint256 maxAmountToMint = (collateralValueInUsd / 2) - totalMinted;
        if (maxAmountToMint <= 0) {
            return;
        }

        amount = bound(amount, 1, maxAmountToMint);

        vm.prank(sender);
        dsce.mintDSC(amount);
        timesMintIsCalled++;
    }

    function _getCollateralSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}

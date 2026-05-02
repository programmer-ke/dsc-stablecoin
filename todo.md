# in progress
- fuzz tests
# done

Tests:

## **Most Critical (Protocol Safety & Core Functionality)**

1. **Health Factor Calculation Tests**
   - Test that health factor correctly calculates when user is overcollateralized
   - Test that health factor drops below 1 when undercollateralized
   - Test edge cases with multiple collateral types

2. **Liquidation Tests**
   - Test liquidator can liquidate undercollateralized position
   - Test liquidator receives 10% bonus collateral
   - Test partial liquidation works correctly
   - Test liquidation fails if health factor is OK (≥ 1)
   - Test liquidation fails if health factor doesn't improve

3. **Minting & Burning Tests**
   - Test minting DSC increases debt correctly
   - Test burning DSC decreases debt correctly
   - Test minting reverts if health factor would break
   - Test burning reverts if health factor would break

4. **Deposit & Redeem Edge Cases**
   - Test redeeming collateral reverts if health factor would break
   - Test depositing multiple collateral types
   - Test redeeming from empty collateral balance

## **High Priority (User Safety & Edge Cases)**

5. **Price Feed Tests**
   - Test handling of stale price feed data
   - Test handling of negative prices (if possible)
   - Test price feed precision calculations

6. **Reentrancy Protection Tests**
   - Test that nonReentrant modifier prevents reentrancy attacks
   - Test on deposit, redeem, mint, burn, and liquidate functions

7. **Token Approval & Transfer Tests**
   - Test deposit reverts if transferFrom fails
   - Test redeem reverts if transfer fails
   - Test insufficient allowance handling

## **Medium Priority (Functionality & Integration)**

8. **Combined Function Tests**
   - Test `depositCollateralAndMintDsc()` works correctly
   - Test `redeemCollateralForDsc()` works correctly
   - Test these combined functions maintain proper health factor

9. **Account Information Tests**
   - Test `getAccountInformation()` returns correct values
   - Test `getAccountCollateralValue()` with multiple tokens
   - Test `getUsdValue()` and `getTokenAmountFromUsd()` precision

10. **Constructor & Initialization Tests**
    - Test constructor sets price feeds correctly
    - Test collateral tokens array is populated

## **Lower Priority (Edge Cases & Gas Optimization)**

11. **Zero Address & Input Validation**
    - Test deposit with zero address token
    - Test all functions with extreme values (max uint256)

12. **Event Emission Tests**
    - Test `CollateralDeposited` event emits correctly
    - Test `CollateralRedeemed` event emits correctly

13. **View Function Tests**
    - Test `getHealthFactor()` (currently empty - needs implementation)
    - Test all view functions with various states

14. **Multi-User Scenario Tests**
    - Test multiple users interacting simultaneously
    - Test user can't redeem another user's collateral

**Most critical to implement first:** Health factor and liquidation
tests, as these are core to protocol safety and preventing insolvency.


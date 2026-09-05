## Use Case: Connected User Liquidates an Undercollateralized Position

**Actor:**  
A connected user who has found an undercollateralized position and
wants to liquidate it to earn a 10% bonus.

**Preconditions:**  
- Wallet is connected (`ConnectionState.CONNECTED`)
- User is on Sepolia (`0xaa36a7`)
- The `DSCEngine` contract ABI and address are available
- An `ethers.BrowserProvider` and `Signer` have been instantiated
- The user has already checked a target address and confirmed its
  health factor is < 1
- The liquidation form is visible with the target's total debt
  populated

**Trigger:**  
The user selects a collateral token to seize, enters a debt-to-cover
amount, and clicks **Liquidate**.

**Flow:**

1. The dApp reads the selected collateral token and debt-to-cover
   amount from the form.
2. It validates that the debt-to-cover amount is > 0 and ≤ the
   target's total debt.
3. The dApp calls:
   ```solidity
   DSCEngine.liquidate(collateralAddress, targetAddress, debtToCover)
   ```
4. The user confirms the transaction in their wallet.
5. Upon success, the dApp re-fetches state via `loadAppState()`.
6. The UI updates:
   - The liquidator's wallet balance for the seized collateral token
     increases (with 10% bonus).
   - The liquidation form resets or hides if the position is now
     healthy.

**Postconditions:**  
- The liquidator receives the seized collateral (value of debt
  covered + 10% bonus).
- The target's debt decreases by the covered amount.
- The target's collateral decreases by the seized amount.
- If the target's health factor is restored to ≥ 1, the position is no
  longer liquidatable.

**Edge Cases to Consider:**  
- **Debt-to-cover is zero** → button is disabled; contract reverts
  with `DSCEngine__NeedsMoreThanZero`
- **Debt-to-cover exceeds target's debt** → dApp disables the button
  or shows "Amount exceeds debt"
- **Health factor is now ≥ 1** → contract reverts with
  `DSCEngine__HealthFactorOk`; dApp should warn
- **Liquidation doesn't improve health factor** → contract reverts
  with `DSCEngine__HealthFactorNotImproved`
- **User rejects transaction** → dApp shows "Transaction cancelled",
  form remains filled
- **Network error** → dApp catches the error, shows a network error
  message, and allows retry

---

**Implementation Note:**  
The current `ui/global.js` and `ui/contract_interaction.js` do not yet
have a handler or service function for the **Liquidate** button
(`#btn-liquidate`). This use case describes the intended behavior for
that missing functionality.

## Use Case: Connected User Finds Undercollateralized Positions

**Actor:**  
A user who has connected their wallet on the supported Sepolia network
and wants to find undercollateralized positions to liquidate for
profit.

**Preconditions:**  
- Wallet is connected (`ConnectionState.CONNECTED`)
- User is on the supported chain (`0xaa36a7`)
- The `DSCEngine` contract ABI and address are available in the
  frontend
- An `ethers.BrowserProvider` and `Signer` have been instantiated

**Trigger:**  
The user enters a target address into the "User Address" input field
and clicks the **Check** button.

**Flow:**

1. The dApp reads the target address from the input field.
2. It validates that the address is a valid Ethereum address.
3. The dApp calls `DSCEngine.getHealthFactor(targetAddress)`.
4. The dApp calls `DSCEngine.getAccountInformation(targetAddress)` to
   get the total collateral value and total DSC debt.
5. The UI updates the "Position Summary" card:
   - **Health Factor** (`#liquidation-hf`) displays the value, with a
     warning state if < 1.
   - **Total Collateral (USD)** (`#liquidation-collateral-value`)
     displays the collateral value.
   - **Total DSC Debt** (`#liquidation-debt`) displays the debt.
6. If the health factor is < 1 (undercollateralized):
   - The "Liquidation Form" becomes visible.
   - The "Total debt" span (`#liquidation-total-debt`) is populated
     with the user's debt.
   - The "Liquidate" button is enabled (once a valid debt-to-cover
     amount is entered).
7. If the health factor is ≥ 1 (healthy):
   - The "Liquidation Form" remains hidden.
   - A status message indicates the position is healthy.

**Postconditions:**
- The user can see the target address's position health at a glance.
- If the position is undercollateralized, the user is presented with
  the liquidation form to proceed with a liquidation.

**Edge Cases to Consider:**
- **Invalid address format:** The dApp shows an error message and does
  not make the contract calls.
- **Address has no position:** Health factor returns max uint256,
  collateral and debt are 0. The UI displays "∞" or "N/A" for health
  factor and "0.00" for values. The liquidation form remains hidden.
- **Network error:** The dApp catches the error, shows a network error
  message, and resets the position summary to `--`.
- **Health factor is exactly 1:** The position is considered healthy
  (not liquidatable). The liquidation form remains hidden.

## Use Case: Connected User Burns DSC and Redeems Collateral in One Step

**Actor:**  
A user who has connected their wallet on Sepolia, has a non-zero DSC
debt, holds enough DSC in their wallet to cover the repayment, and has
deposited collateral they wish to withdraw.

**Preconditions:**  
- Wallet is connected (`ConnectionState.CONNECTED`)
- User is on Sepolia (`0xaa36a7`)
- The `DSCEngine`, `DecentralizedStableCoin`, WETH, and WBTC contract
  ABIs and addresses are available
- An `ethers.BrowserProvider` and `Signer` have been instantiated
- The user has a non-zero DSC debt (`totalDscMinted > 0`)
- The user has a DSC wallet balance ≥ the amount they wish to burn
- The user has a non-zero deposited balance of the selected collateral
  token
- The burn amount and redeem amount are both greater than 0
- After both actions, the user’s projected health factor remains ≥
  `MIN_HEALTH_FACTOR`

**Trigger:**  
The user selects a collateral token, enters a DSC burn amount and a
collateral redeem amount, then clicks **Burn & Redeem**.

**Flow:**

1. The dApp reads the burn amount and redeem amount from the form.
2. It validates that both amounts are > 0.
3. It checks that the burn amount does not exceed the user’s DSC
   wallet balance or total DSC debt.
4. It checks that the redeem amount does not exceed the user’s
   deposited balance for the selected token.
5. Optionally, it shows a health factor preview for the combined
   action using `calculateHealthFactor` or equivalent logic.
6. The dApp calls `approve(DSC_ENGINE_ADDRESS, burnAmount)` on the DSC
   token contract.
7. After the approval is confirmed, the dApp calls:
   ```solidity
   DSCEngine.burnDsc(burnAmount)
   ```
8. The user confirms the burn transaction in their wallet.
9. Upon successful burn, the dApp then calls: ```solidity
   DSCEngine.redeemCollateral(tokenAddress, redeemAmount) ``` (No
   additional approval is needed for redemption.)
10. The user confirms the redeem transaction in their wallet.
11. Upon success of both transactions, the dApp re-fetches state via
    `loadAppState()` or a targeted refresh.
12. The UI updates:
    - Total DSC debt decreases by the burned amount
    - DSC wallet balance decreases by the burned amount
    - Wallet balance for the redeemed token increases by the redeemed
      amount
    - Collateral breakdown table shows the reduced deposited balance
      and USD value
    - Health factor is recalculated

**Postconditions:**  
- The user’s DSC debt is reduced by the burned amount
- The burned DSC tokens are destroyed
- The redeemed collateral is transferred from the `DSCEngine` back to
  the user’s wallet
- The dashboard reflects the updated debt, collateral position, and
  health factor

**Edge Cases to Consider:**  
- **Burn amount is zero** → button is disabled; contract reverts with
  `DSCEngine__NeedsMoreThanZero`
- **Redeem amount is zero** → button is disabled; contract reverts
  with `DSCEngine__NeedsMoreThanZero`
- **Insufficient DSC balance** → dApp disables the button or shows
  “Insufficient DSC balance”
- **Burn amount exceeds debt** → dApp disables the button or shows
  “Amount exceeds debt”
- **Redeem amount exceeds deposited balance** → dApp disables the
  button or shows “Insufficient deposited balance”
- **Combined action would break health factor** → contract reverts
  with `DSCEngine__BreaksHealthFactor` on either burn or redeem; dApp
  should warn or disable
- **User rejects approval** → dApp stops, displays “Approval
  cancelled”, and does not proceed
- **User rejects burn transaction** → dApp displays “Transaction
  cancelled”, form remains filled, redeem is not attempted
- **Burn succeeds but redeem fails** → dApp shows failure message for
  redeem; the burn has already reduced debt, so the user may need to
  retry the redeem separately. The dApp should refresh state and allow
  the user to attempt the redeem again.
- **Network error during any step** → dApp catches the error, shows a
  network error message, and allows retry from the failed step
- **Token not allowed for redeem** → contract reverts with
  `DSCEngine__TokenNotAllowed`

**Implementation Note:**  
The supplied `ui/global.js` currently has a **Burn & Redeem** button
(`#btn-burn-redeem`) but no handler or service function for it, and
`ui/contract_interaction.js` does not yet expose a combined
wrapper. This use case describes the intended behavior for that
missing functionality. The implementation will need to orchestrate two
sequential transactions (approve + burn, then redeem) and handle
partial failures gracefully.

## Use Case: Connected User Redeems Collateral Only

**Actor:**  
A user who has connected their wallet on Sepolia, has a non-zero
deposited balance of WETH or WBTC, and wants to withdraw some
collateral without repaying DSC.

**Preconditions:**  
- Wallet is connected (`ConnectionState.CONNECTED`)
- User is on Sepolia (`0xaa36a7`)
- The `DSCEngine` and collateral token contract ABIs and addresses are
  available
- An `ethers.BrowserProvider` and `Signer` have been instantiated
- The user has a non-zero deposited balance of the selected collateral
  token
- The redemption amount is greater than 0
- After redeeming, the user’s projected health factor remains ≥
  `MIN_HEALTH_FACTOR`

**Trigger:**  
The user selects a collateral token, enters an amount, and clicks
**Redeem Only**.

**Flow:**

1. The dApp reads the selected collateral token and redemption amount
   from the form.
2. It validates that the amount is > 0.
3. It checks that the amount does not exceed the user’s deposited
   balance for that token.
4. Optionally, it shows a health factor preview for the redemption
   using `calculateHealthFactor` or equivalent logic.
5. The dApp calls:
   ```solidity
   DSCEngine.redeemCollateral(tokenAddress, amountCollateral)
   ```
6. The user confirms the transaction in their wallet.
7. Upon success, the dApp re-fetches state via `loadAppState()` or a
   targeted refresh.
8. The UI updates:
   - Wallet balance for the redeemed token increases by the redeemed
     amount
   - Collateral breakdown table shows the reduced deposited balance
     and USD value
   - Health factor is recalculated
   - Total DSC debt remains unchanged

**Postconditions:**  
- The collateral is transferred from the `DSCEngine` back to the
  user’s wallet
- The user’s deposited balance for that token decreases
- The dashboard reflects the updated collateral position and health
  factor

**Edge Cases to Consider:**  
- **Redeeming zero amount** → button is disabled; contract reverts
  with `DSCEngine__NeedsMoreThanZero`
- **Redeeming more than deposited balance** → dApp disables the button
  or shows “Insufficient deposited balance”
- **Redemption would break health factor** → contract reverts with
  `DSCEngine__BreaksHealthFactor`; dApp should warn or disable
- **User rejects the transaction** → dApp shows “Transaction
  cancelled”, form remains filled
- **Token not allowed** → contract reverts with
  `DSCEngine__TokenNotAllowed`
- **Network error during redemption** → dApp catches the error, shows
  a network error message, and allows retry
- **Approval is not required** for redeeming collateral because the
  engine transfers collateral back to the user

**Implementation Note:**  
The supplied `ui/global.js` currently has a **Redeem Only** button
(`#btn-redeem-only`) but no handler or service function for it, and
`ui/contract_interaction.js` does not yet expose a wrapper for
`redeemCollateral`. This use case describes the intended behavior for
that missing functionality.

## Use Case: Connected User Burns DSC (Repays Debt)

**Actor:**  
A user who has connected their wallet on Sepolia, has a non-zero DSC
debt, and holds enough DSC in their wallet to cover the repayment.

**Preconditions:**  
- Wallet is connected (`ConnectionState.CONNECTED`)
- User is on Sepolia (`0xaa36a7`)
- The `DSCEngine` and `DecentralizedStableCoin` contract ABIs and
  addresses are available
- An `ethers.BrowserProvider` and `Signer` have been instantiated
- The user has a non-zero DSC debt (`totalDscMinted > 0`)
- The user has a DSC wallet balance ≥ the amount they wish to burn
- After burning, the user’s health factor remains ≥
  `MIN_HEALTH_FACTOR` (or improves)

**Trigger:**  
The user enters an amount of DSC to burn and clicks **Burn Only**.

**Flow:**

1. The dApp reads the burn amount from the form.
2. It validates that the amount is > 0 and does not exceed the user’s
   DSC wallet balance.
3. Optionally, it shows a health factor preview for the repayment.
4. The dApp calls `approve(DSC_ENGINE_ADDRESS, burnAmount)` on the DSC
   token contract.
5. After the approval is confirmed, the dApp calls:
   ```solidity
   DSCEngine.burnDsc(burnAmount)
   ```
6. The user confirms the transaction in their wallet.
7. Upon success, the dApp re-fetches state via `loadAppState()` or a
   targeted refresh.
8. The UI updates:
   - Total DSC debt (`#total-dsc-debt`) decreases by the burned amount
   - DSC wallet balance decreases by the burned amount
   - Health factor improves (increases) if collateral value remains
     unchanged

**Postconditions:**  
- The user’s DSC debt in the `DSCEngine` is reduced by the burned
  amount
- The burned DSC tokens are destroyed
- The dashboard reflects the updated debt, health factor, and DSC
  balance

**Edge Cases to Consider:**  
- **Insufficient DSC balance** → dApp disables the button or shows
  “Insufficient DSC balance”
- **Burn amount is zero** → button is disabled; contract reverts with
  `DSCEngine__NeedsMoreThanZero`
- **Health factor already broken** → burning may still leave health
  factor below `MIN_HEALTH_FACTOR`, causing
  `DSCEngine__BreaksHealthFactor` revert; dApp should warn or disable
- **User rejects approval** → dApp stops, displays “Approval
  cancelled”, and does not call `burnDsc`
- **User rejects the burn transaction** → dApp displays “Transaction
  cancelled”, form remains filled
- **Approval succeeds but burn fails** → dApp shows failure message;
  user may not need to re-approve if allowance remains
- **Network error during approval or burn** → dApp catches the error,
  shows a network error message, and allows retry

**Implementation Note:**  
The supplied `ui/global.js` currently has a **Burn Only** button
(`#btn-burn-only`) but no handler or service function for it, and
`ui/contract_interaction.js` does not yet expose a wrapper for
`burnDsc`. This use case describes the intended behavior for that
missing functionality.

## Use Case: Connected User Deposits Collateral and Mints DSC in One Step

**Actor:**  
A user who has connected their wallet on Sepolia, has a non-zero
balance of WETH or WBTC, and wants to deposit collateral and borrow
DSC in a single action.

**Preconditions:**  
- Wallet is connected (`ConnectionState.CONNECTED`)
- User is on Sepolia (`0xaa36a7`)
- The `DSCEngine`, `DecentralizedStableCoin`, WETH, and WBTC contract
  ABIs and addresses are available
- An `ethers.BrowserProvider` and `Signer` have been instantiated
- The user has a non-zero wallet balance of the selected collateral
  token
- The deposit and mint amounts are greater than 0
- After the combined action, the user’s projected health factor
  remains ≥ `MIN_HEALTH_FACTOR`

**Trigger:**  
The user selects a collateral token, enters a deposit amount and a DSC
mint amount, then clicks **Deposit & Mint**.

**Flow:**

1. The dApp reads the selected token address, collateral amount, and
   DSC amount from the form.
2. It validates that both amounts are > 0.
3. It checks that the collateral amount does not exceed the user’s
   wallet balance.
4. Optionally, it shows a health factor preview for the combined
   action using `calculateHealthFactor` or equivalent logic.
5. The dApp calls `approve(DSC_ENGINE_ADDRESS, collateralAmount)` on
   the selected collateral token.
6. After the approval is confirmed, the dApp calls:
   ```solidity
   DSCEngine.depositCollateralAndMintDsc(
       tokenAddress,
       collateralAmount,
       dscAmountToMint
   )
   ```
7. The user confirms the combined transaction in their wallet.
8. Upon success, the dApp re-fetches state via `loadAppState()` or a
   targeted refresh.
9. The UI updates:
   - Wallet balance for the deposited token decreases
   - Collateral breakdown table shows the new deposited balance and
     USD value
   - Total DSC debt increases by the minted amount
   - DSC wallet balance increases by the minted amount
   - Health factor is recalculated

**Postconditions:**  
- The collateral is locked in the `DSCEngine`
- New DSC is minted to the user’s wallet
- The user’s debt increases by the minted amount
- The dashboard reflects the updated position

**Edge Cases to Consider:**  
- **Combined transaction would break health factor** → contract
  reverts with `DSCEngine__BreaksHealthFactor`; dApp should show a
  descriptive error and keep the form intact
- **Insufficient collateral balance** → dApp disables the button or
  shows “Insufficient balance”
- **User rejects approval** → dApp stops, displays “Approval
  cancelled”, and does not call the combined deposit/mint
- **User rejects the combined transaction** → dApp displays
  “Transaction cancelled”, form remains filled
- **Zero deposit or mint amount** → button is disabled; contract
  reverts with `DSCEngine__NeedsMoreThanZero`
- **Token not allowed** → contract reverts with
  `DSCEngine__TokenNotAllowed`
- **Network error during approval or combined transaction** → dApp
  catches the error, shows a network error message, and allows retry
- **Approval succeeds but combined transaction fails** → dApp shows
  failure message; the user may not need to re-approve if allowance
  remains

**Implementation Note:**  
The supplied `ui/global.js` currently has a **Deposit & Mint** button
(`#btn-deposit-mint`) but no handler or service function for it, and
`ui/contract_interaction.js` does not yet expose a wrapper for
`depositCollateralAndMintDsc`. This use case describes the intended
behavior for that missing functionality.

## Use Case: Connected User Mints DSC

**Actor:** A user who has connected their wallet on the supported
Sepolia network, has already deposited collateral, and has a health
factor that allows additional minting.

**Preconditions:**
- Wallet is connected (`ConnectionState.CONNECTED`)
- User is on the supported chain (`0xaa36a7`)
- The `DSCEngine` contract ABI and address are available in the
  frontend
- An `ethers.BrowserProvider` and `Signer` have been instantiated
- The user has a non-zero collateral balance deposited in the
  `DSCEngine`
- The user's current health factor is above the minimum required after
  minting the desired amount

**Trigger:** The user enters an amount of DSC to mint and clicks the
**Mint DSC** button.

**Flow:**

1. The dApp reads the mint amount from the form.
2. It validates that the amount is > 0.
3. The dApp optionally calculates the projected health factor after
   minting (using `calculateHealthFactor`) to warn the user if the
   mint would break the health factor.
4. The dApp calls `DSCEngine.mintDSC(amount)`.
5. The user confirms the transaction in their wallet.
6. Upon successful minting, the dApp re-fetches the user's position
   (via `loadAppState()` or a targeted refresh).
7. The UI updates:
   - Total DSC debt (`#total-dsc-debt`) increases by the minted
     amount.
   - Health factor decreases (if collateral value unchanged).
   - DSC wallet balance increases by the minted amount.

**Postconditions:**
- The user's DSC debt in the `DSCEngine` is increased by the minted
  amount.
- The user's wallet now holds the newly minted DSC tokens.
- The dashboard reflects the updated debt, health factor, and DSC
  balance.

**Edge Cases to Consider:**
- **Insufficient collateral / health factor too low:** The mint would
  cause the health factor to drop below `MIN_HEALTH_FACTOR`. The dApp
  should disable the button or show a warning before the transaction,
  and the contract will revert with `DSCEngine__BreaksHealthFactor`.
- **Minting zero amount:** The dApp should prevent this by disabling
  the button or validating the input. The contract reverts with
  `DSCEngine__NeedsMoreThanZero`.
- **User rejects the transaction:** The dApp catches the rejection and
  shows a message like "Mint cancelled".
- **Transaction fails on-chain:** (e.g., due to a contract revert) →
  the dApp shows an error and the form remains intact.
- **Network error during transaction:** The dApp catches the error and
  displays a status message.
- **User has no collateral deposited:** The health factor calculation
  would result in a value that likely prevents minting (or the
  contract reverts). The dApp should detect this and inform the user.

## Use Case: Connected User Deposits Collateral**

**Actor:** A user who has connected their wallet on the supported
Sepolia network and holds WETH or WBTC in their wallet.

**Preconditions:**
- Wallet is connected (`ConnectionState.CONNECTED`)
- User is on the supported chain (`0xaa36a7`)
- The `DSCEngine` contract ABI and address are available in the
  frontend
- An `ethers.BrowserProvider` and `Signer` have been instantiated
- The user has a non-zero balance of the selected collateral token
  (WETH or WBTC)

**Trigger:** The user selects a collateral token, enters an amount,
and clicks the **Deposit Only** button (or **Deposit & Mint** if they
also want to mint DSC).

**Flow:**

1. The dApp reads the selected token address and amount from the form.
2. It validates that the amount is > 0 and does not exceed the user's
   wallet balance.
3. The dApp calls `approve(DSC_ENGINE_ADDRESS, amount)` on the
   selected token contract, prompting the user to confirm the
   transaction in their wallet.
4. After the approval is confirmed, the dApp calls
   `DSCEngine.depositCollateral(tokenAddress, amount)`.
5. The user confirms the deposit transaction in their wallet.
6. Upon successful deposit, the dApp re-fetches the user's wallet
   balances and collateral breakdown (via `loadAppState()` or a
   targeted refresh).
7. The UI updates:
   - Wallet balance for the deposited token decreases.
   - Collateral breakdown table shows the new deposited balance and
     USD value.
   - Health factor and total DSC debt may update if the deposit
     affects the position (e.g., if the user had existing debt, health
     factor improves).

**Postconditions:**
- The deposited collateral is locked in the `DSCEngine` contract.
- The user's wallet balance for that token is reduced by the deposited
  amount.
- The dashboard reflects the updated collateral position.

**Edge Cases to Consider:**
- **Insufficient balance:** The user tries to deposit more than they
  hold → the dApp should disable the button or show an error before
  the transaction.
- **User rejects approval:** The user cancels the `approve`
  transaction → the dApp stops and shows a message like "Approval
  cancelled".
- **User rejects deposit:** The user cancels the `depositCollateral`
  transaction → the dApp stops and shows a message like "Deposit
  cancelled".
- **Approval succeeds but deposit fails:** (e.g., due to a contract
  revert) → the dApp shows an error and the user may need to
  re-approve if they try again.
- **Network error during transaction:** The dApp catches the error and
  displays a status message.
- **Depositing zero amount:** The dApp should prevent this by
  disabling the button or validating the input.
- **Token not allowed:** If the user somehow selects an unsupported
  token (should not happen with the current UI), the contract reverts
  with `DSCEngine__TokenNotAllowed`.


## Use Case: Connected User Views Their Position Overview**

**Actor:** A user who has connected their wallet on the supported Sepolia network.

**Preconditions:**
- Wallet is connected (`ConnectionState.CONNECTED`)
- User is on the supported chain (`0xaa36a7`)
- The `DSCEngine`, `DecentralizedStableCoin`, WETH, and WBTC contract
  ABIs and addresses are available in the frontend
- An `ethers.BrowserProvider` and `Signer` have been instantiated

**Trigger:** The wallet state transitions to `CONNECTED` (or the user switches accounts while connected).

**Flow:**

1. The dApp reads the user's address from `connectedAccounts.accounts[0]`
2. It calls these **view functions** on the `DSCEngine` contract:
   - `getAccountInformation(user)` → returns `(totalDscMinted, collateralValueInUsd)`
   - `getHealthFactor(user)` → returns the current health factor
   - `getCollateralBalanceOfUser(token, user)` for both WETH and WBTC → returns deposited balances
   - `getUsdValue(token, amount)` for each collateral → returns USD value of each deposit
3. It calls `balanceOf(user)` on the **DSC, WETH, and WBTC** token contracts to get wallet balances
4. The UI updates:
   - **Health Factor** card (`#health-factor`) — displays the value, with a warning state if < 1
   - **Total DSC Debt** card (`#total-dsc-debt`) — displays `totalDscMinted`
   - **Wallet Balances** — DSC, WETH, WBTC (`#dsc-balance`, `#weth-balance`, `#wbtc-balance`)
   - **Collateral Breakdown table** — deposited amounts and USD values for WETH and WBTC

**Postconditions:**
- All dashboard placeholders (`--`) are replaced with real values
- The user can see their position health at a glance
- The Borrow and Repay sections can use this data for their own calculations

---

**Edge Cases to Consider:**
- User has no deposits yet → health factor shows as "∞" or "N/A", debt is 0
- User has debt but no collateral → health factor is 0 (shouldn't happen in normal protocol operation)
- Network request fails → show an error status, keep placeholders

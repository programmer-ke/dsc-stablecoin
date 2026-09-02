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

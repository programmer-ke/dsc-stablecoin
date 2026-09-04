# todo

## User Story: Check Position Health (Happy Path)
As a connected user, I want to enter a target address and check their
position health so that I can determine if they are eligible for
liquidation.

**Acceptance Criteria:**
- The user enters a valid Ethereum address into the "User Address"
  input field.
- Clicking the **Check** button fetches the target's health factor,
  total collateral value, and total DSC debt.
- The "Position Summary" card updates to display these values.
- If the health factor is ≥ 1, the "Liquidation Form" remains hidden,
  and a status message indicates the position is healthy.

**Scenarios:**
- **Scenario 1: Checking a healthy position**
  - Given the user enters a valid address with a health factor of 2.0
  - When they click **Check**
  - Then the Position Summary displays HF: 2.0, Collateral: [value],
    Debt: [value]
  - And the Liquidation Form remains hidden
  - And a status message says "Position is healthy"

- **Scenario 2: Checking an undercollateralized position**
  - Given the user enters a valid address with a health factor of 0.8
  - When they click **Check**
  - Then the Position Summary displays HF: 0.8 (with warning state),
    Collateral: [value], Debt: [value]
  - And the Liquidation Form becomes visible
  - And the "Total debt" span is populated with the user's debt

---

## User Story: Prevent Checking with Invalid Address
As a user, I want to be prevented from checking an invalid address so
that I don't trigger unnecessary contract calls.

**Acceptance Criteria:**
- The **Check** button is disabled or shows an error if the entered
  address is not a valid Ethereum address (e.g., not 42 characters,
  doesn't start with 0x).

**Scenarios:**
- **Scenario 1: Invalid address format**
  - Given the user enters "0x123" into the User Address field
  - When they click **Check**
  - Then the dApp shows an error message "Invalid address"
  - And no contract calls are made

---

## User Story: Handle Address with No Position
As a user, I want to see a clear message if the checked address has no
position, so I know they cannot be liquidated.

**Acceptance Criteria:**
- If the checked address has no collateral and no debt, the health
  factor returns max uint256.
- The UI displays "∞" or "N/A" for the health factor.
- Collateral and Debt display "0.00".
- The Liquidation Form remains hidden.

**Scenarios:**
- **Scenario 1: Fresh account**
  - Given the user enters a valid address that has never interacted
    with the protocol
  - When they click **Check**
  - Then the Position Summary displays HF: ∞, Collateral: 0.00, Debt:
    0.00
  - And the Liquidation Form remains hidden

---

## User Story: Handle Network Error During Check
As a user, if a network error occurs while checking a position, I want
to be informed so I can retry.

**Acceptance Criteria:**
- If the RPC calls to fetch health factor or account information fail,
  the dApp catches the error.
- A status message is shown (e.g., "Network error, please try again").
- The Position Summary resets to `--`.

**Scenarios:**
- **Scenario 1: RPC fails**
  - Given the user enters a valid address and clicks **Check**
  - When the `getHealthFactor` or `getAccountInformation` RPC call
    fails
  - Then the dApp shows "Network error, please try again"
  - And the Position Summary fields show `--`

## User Story: Inform User When No Collateral Deposited
As a user with no collateral deposited, I want to be informed that I
cannot mint DSC so that I understand why the feature is unavailable.

**Acceptance Criteria:**
- If the user has no collateral deposited (collateral value = 0), the
  mint button is disabled
- A message is shown explaining that collateral must be deposited
  first

**Scenarios:**
- **Scenario 1: No collateral deposited**
  - Given the user is connected but has never deposited collateral
  - When the dashboard loads
  - Then the mint button is disabled and a message like "Deposit
    collateral to mint DSC" is shown

## User Story: Repay Debt

- [ ] **Scenario 6: User repays debt and dashboard refreshes**
 - **Given** the user has debt and the dashboard is displaying it
 - **When** the user repays some DSC (in another tab or via the dApp) and the dashboard re-fetches
 - **Then** the new, lower debt value is displayed in `#total-dsc-debt`
 - **And** if fully repaid, displays "0.00"

---

# in progress


# done

## User Story 53: Prevent Burn & Redeem with Zero Amounts
As a user, I want the dApp to prevent me from burning 0 DSC or
redeeming 0 collateral, so I don't waste gas.

**Acceptance Criteria:**
- The **Burn & Redeem** button is disabled when either the burn amount
  or the redeem amount is 0 or empty

**Scenarios:**
- **Scenario 1: Burn amount is 0**
  - Given the user enters 0 in the burn amount field and a positive
    redeem amount
  - Then the **Burn & Redeem** button is disabled

- **Scenario 2: Redeem amount is 0**
  - Given the user enters a positive burn amount and 0 in the redeem
    amount field
  - Then the **Burn & Redeem** button is disabled

- **Scenario 3: Both fields are empty**
  - Given both the burn and redeem amount fields are blank
  - Then the **Burn & Redeem** button is disabled

---

## User Story 54: Prevent Burn & Redeem with Insufficient DSC Balance
As a user, I want the dApp to prevent me from attempting to burn more
DSC than I hold in my wallet.

**Acceptance Criteria:**
- The **Burn & Redeem** button is disabled when the entered burn
  amount > DSC wallet balance
- A warning message is shown (e.g., "Insufficient DSC balance")

**Scenarios:**
- **Scenario 1: Amount exceeds balance**
  - Given the user has 100 DSC in wallet
  - When they enter 150 DSC to burn and a valid redeem amount
  - Then the **Burn & Redeem** button is disabled and a warning is
    displayed

- **Scenario 2: Amount equals balance (valid)**
  - Given the user has 100 DSC in wallet
  - When they enter 100 DSC and a valid redeem amount
  - Then the **Burn & Redeem** button is enabled (provided other
    conditions are met)

---

## User Story 55: Prevent Burn & Redeem When Burn Exceeds Debt
As a user, I want the dApp to prevent me from burning more DSC than my
current debt.

**Acceptance Criteria:**
- The **Burn & Redeem** button is disabled when the entered burn
  amount > total DSC debt
- A warning message is shown (e.g., "Amount exceeds debt")

**Scenarios:**
- **Scenario 1: Amount exceeds debt**
  - Given the user has 200 DSC debt and 500 DSC in wallet
  - When they enter 300 DSC to burn and a valid redeem amount
  - Then the **Burn & Redeem** button is disabled and a warning is
    displayed

- **Scenario 2: Amount equals debt (valid)**
  - Given the user has 200 DSC debt
  - When they enter 200 DSC and a valid redeem amount
  - Then the **Burn & Redeem** button is enabled

---

## User Story 56: Prevent Redeeming More Than Deposited Balance in Burn & Redeem
As a user, I want the dApp to prevent me from redeeming more
collateral than I have deposited when using the combined action.

**Acceptance Criteria:**
- The **Burn & Redeem** button is disabled when the entered redeem
  amount > deposited balance for the selected token
- A warning message is shown (e.g., "Insufficient deposited balance")

**Scenarios:**
- **Scenario 1: Amount exceeds deposited balance**
  - Given the user has 1 WETH deposited
  - When they enter 2 WETH to redeem and a valid burn amount
  - Then the **Burn & Redeem** button is disabled and a warning is
    displayed

- **Scenario 2: Amount equals deposited balance (valid)**
  - Given the user has 1 WETH deposited
  - When they enter 1 WETH and a valid burn amount
  - Then the **Burn & Redeem** button is enabled

---

## User Story 57: Warn When Burn & Redeem Would Break Health Factor
As a user, I want to be warned before executing the combined action if
it would cause my health factor to drop below the minimum.

**Acceptance Criteria:**
- The dApp calculates the projected health factor after both burn and
  redeem (using `calculateHealthFactor`)
- If the projected health factor < `MIN_HEALTH_FACTOR`, a warning is
  shown
- The warning message explains that the combined action would break
  the health factor

**Scenarios:**
- **Scenario 1: Combined action would break health factor**
  - Given the user has a health factor of 1.1
  - When they enter burn and redeem amounts that would drop the health
    factor below 1
  - Then a warning is displayed

- **Scenario 2: Combined action is safe**
  - Given the user has a health factor of 2.0
  - When they enter amounts that keep the health factor ≥ 1
  - Then no warning is shown

---

## User Story 58: Handle User Rejection of Approval in Burn & Redeem
As a user, if I reject the DSC approval transaction during the
combined flow, I expect the dApp to cancel gracefully and show a clear
message.

**Acceptance Criteria:**
- When the user rejects the `approve` transaction, the dApp catches
  the error
- The burn and redeem do not proceed
- A status message is shown (e.g., "Approval cancelled")
- The UI remains consistent

**Scenarios:**
- **Scenario 1: User rejects approval**
  - Given the user clicks **Burn & Redeem**
  - When the MetaMask approval prompt appears and the user clicks
    "Reject"
  - Then the dApp shows "Approval cancelled" and does not call
    `burnDsc` or `redeemCollateral`

---


## User Story 59: Handle On-Chain Failure of Burn in Combined Flow
As a user, if the burn transaction fails on-chain, I want to see a
descriptive error and the redeem should not be attempted.

**Acceptance Criteria:**
- If `burnDsc` reverts (e.g., `DSCEngine__BreaksHealthFactor` or
  `DSCEngine__NeedsMoreThanZero`), the dApp catches the error
- A descriptive error message is shown
- The redeem is not attempted
- The UI does not crash; the user can try again

**Scenarios:**
- **Scenario 1: Burn reverts due to health factor**
  - Given the user attempts a burn that would break the health factor
    (and the frontend check was bypassed)
  - When the transaction reverts with `DSCEngine__BreaksHealthFactor`
  - Then the dApp displays the error reason and the form remains
    intact; redeem is not called

---

## User Story 60: Handle Network Error During Burn & Redeem
As a user, if a network error occurs at any step, I want to be
informed so I can retry.

**Acceptance Criteria:**
- If any RPC call throws a network error, the dApp catches it
- A status message is shown (e.g., "Network error, please try again")
- The form remains filled and the user can retry from the failed step

**Scenarios:**
- **Scenario 1: Network error during approval**
  - Given the user clicks **Burn & Redeem**
  - When the approval RPC call fails due to a network issue
  - Then the dApp shows "Network error, please try again" and the form
    remains intact

- **Scenario 2: Network error during burn**
  - Given the approval succeeded
  - When the `burnDsc` RPC call fails due to a network issue
  - Then the dApp shows "Network error, please try again" and the form
    remains intact

- **Scenario 3: Network error during redeem**
  - Given the burn succeeded
  - When the `redeemCollateral` RPC call fails due to a network issue
  - Then the dApp shows "Network error, please try again", refreshes
    state, and the form remains filled

---

## User Story 61: Refresh Dashboard After Burn & Redeem
As a user, after a successful burn and redeem, I want the dashboard to
automatically update all relevant data.

**Acceptance Criteria:**
- After both transactions are confirmed, `loadAppState()` is triggered
- Wallet balances, collateral breakdown, health factor, and total debt
  are refreshed
- The updated values are displayed within a few seconds

**Scenarios:**
- **Scenario 1: Dashboard refreshes after burn and redeem**
  - Given the user burns 100 DSC and redeems 0.5 WETH
  - When both transactions are mined
  - Then debt decreases by 100, DSC balance decreases by 100, WETH
    wallet balance increases by 0.5, deposited WETH decreases by 0.5,
    and health factor updates

## User Story 52: Burn & Redeem (Happy Path)
As a connected user with DSC debt and deposited collateral, I want to
burn DSC and redeem collateral in one step so that I can reduce my
debt and withdraw assets efficiently.

**Acceptance Criteria:**
- The user selects a collateral token, enters a burn amount > 0 and a
  redeem amount > 0
- The dApp validates both amounts are valid (burn ≤ DSC balance, burn
  ≤ debt, redeem ≤ deposited balance)
- Clicking **Burn & Redeem** triggers `approve` on DSC, then
  `burnDsc`, then `redeemCollateral`
- After both transactions confirm, the dashboard refreshes:
  - Total DSC debt decreases by the burned amount
  - DSC wallet balance decreases by the burned amount
  - Wallet balance for the redeemed token increases by the redeemed
    amount
  - Collateral breakdown table shows the reduced deposited balance and
    USD value
  - Health factor is recalculated

**Scenarios:**
- [x] **Scenario 1: Successful burn and redeem**
  - Given the user has 500 DSC debt, 600 DSC in wallet, and 2 WETH
    deposited
  - When they burn 200 DSC and redeem 1 WETH
  - Then debt becomes 300 DSC, wallet DSC becomes 400, WETH wallet
    balance increases by 1, deposited WETH becomes 1, and health
    factor updates

- [x] **Scenario 2: Full repayment and full redemption**
  - Given the user has 100 DSC debt, 100 DSC in wallet, and 0.5 WBTC
    deposited
  - When they burn 100 DSC and redeem 0.5 WBTC
  - Then debt becomes 0, DSC wallet becomes 0, WBTC wallet balance
    increases by 0.5, deposited WBTC becomes 0, and health factor
    shows "OK"

---
## User Story 51: Refresh Dashboard After Redeem
As a user, after a successful redemption, I want the dashboard to
automatically update all relevant data.

**Acceptance Criteria:**
- After the redeem transaction is confirmed, `loadAppState()` is
  triggered
- Wallet balances, collateral breakdown, and health factor are
  refreshed
- The updated values are displayed within a few seconds

**Scenarios:**
- **Scenario 1: Dashboard refreshes after redeem**
  - Given the user redeems 1 WETH
  - When the transaction is mined
  - Then the WETH wallet balance increases, collateral table shows the
    reduced deposit, and health factor updates if applicable

## User Story 50: Handle Network Error During Redeem
As a user, if a network error occurs while redeeming, I want to be
informed so I can retry.

**Acceptance Criteria:**
- If the RPC call throws a network error, the dApp catches it
- A status message is shown (e.g., "Network error, please try again")
- The form remains filled and the user can retry

**Scenarios:**
- **Scenario 1: Network error during redeem**
  - Given the user clicks **Redeem Only**
  - When the `redeemCollateral` RPC call fails due to a network issue
  - Then the dApp shows "Network error, please try again" and the form
    remains intact

## User Story 49: Handle On-Chain Failure of Redeem
As a user, if the redeem transaction fails on-chain, I want to see a
descriptive error message.

**Acceptance Criteria:**
- If `redeemCollateral` reverts (e.g.,
  `DSCEngine__BreaksHealthFactor`, `DSCEngine__NeedsMoreThanZero`, or
  `DSCEngine__TokenNotAllowed`), the dApp catches the error
- A descriptive error message is shown (e.g., "Transaction failed:
  health factor too low")
- The UI does not crash; the user can try again

**Scenarios:**
- **Scenario 1: Redeem reverts due to health factor**
  - Given the user attempts to redeem an amount that would break the
    health factor (and the frontend check was bypassed)
  - When the transaction reverts with `DSCEngine__BreaksHealthFactor`
  - Then the dApp displays the error reason and the form remains
    intact

- **Scenario 2: Redeem reverts due to zero amount**
  - Given the user approved the redeem but the amount is zero due to
    stale state
  - When the transaction reverts with `DSCEngine__NeedsMoreThanZero`
  - Then the dApp displays the error reason

---
## User Story 48: Handle User Rejection of Redeem Transaction
As a user, if I reject the redeem transaction in my wallet, I expect
the dApp to cancel gracefully and show a clear message.

**Acceptance Criteria:**
- When the user rejects `redeemCollateral`, the dApp catches the error
- A status message is shown (e.g., "Transaction cancelled")
- The form remains filled and the UI stays consistent

**Scenarios:**
- **Scenario 1: User rejects redeem**
  - Given the user clicks **Redeem Only**
  - When the wallet confirmation appears and the user rejects it
  - Then the dApp shows "Transaction cancelled" and the form remains
    filled

---


## User Story 47: Warn When Redeem Would Break Health Factor
As a user, I want to be warned before redeeming if the withdrawal
would cause my health factor to drop below the minimum, so I can avoid
a failed transaction.

**Acceptance Criteria:**
- The dApp calculates the projected health factor after redemption
  using `calculateHealthFactor`
- If the projected health factor < `MIN_HEALTH_FACTOR`, a warning is
  shown
- The warning message explains that the redemption would break the
  health factor

**Scenarios:**
- [x] **Scenario 1: Redemption would break health factor**
  - Given the user has a health factor of 1.1
  - When they enter a redeem amount that would drop the health factor
    below 1
  - Then a warning is displayed

- [x] **Scenario 2: Redemption is safe**
  - Given the user has a health factor of 2.0
  - When they enter an amount that keeps the health factor ≥ 1
  - Then no warning is shown


## User Story 46: Prevent Redeeming More Than Deposited Balance
As a user, I want the dApp to prevent me from attempting to redeem
more collateral than I have deposited, because the contract would
revert.

**Acceptance Criteria:**
- The **Redeem Only** button is disabled when the entered amount >
  deposited balance for the selected token
- A warning message is shown (e.g., "Insufficient deposited balance")

**Scenarios:**
- **Scenario 1: Amount exceeds deposited balance**
  - Given the user has 1 WETH deposited
  - When they enter 2 WETH to redeem
  - Then the **Redeem Only** button is disabled and a warning is
    displayed

- **Scenario 2: Amount equals deposited balance (valid)**
  - Given the user has 1 WETH deposited
  - When they enter 1 WETH
  - Then the **Redeem Only** button is enabled, provided other
    conditions are met


## User Story 45: Prevent Redeeming Zero Amount
As a user, I want the dApp to prevent me from redeeming 0 collateral
so I don’t waste gas.

**Acceptance Criteria:**
- The **Redeem Only** button is disabled when the redeem amount is 0
  or empty

**Scenarios:**
- **Scenario 1: Amount is 0**
  - Given the user enters 0 in the collateral redeem amount field
  - Then the **Redeem Only** button is disabled

- **Scenario 2: Amount is empty**
  - Given the collateral redeem amount field is blank
  - Then the **Redeem Only** button is disabled


## User Story 44: Redeem Collateral (Happy Path)
As a connected user with deposited WETH or WBTC, I want to redeem some
collateral without repaying DSC so that I can withdraw my assets.

**Acceptance Criteria:**
- The user selects a collateral token and enters an amount > 0
- The dApp validates that the amount does not exceed the user’s
  deposited balance
- Clicking **Redeem Only** calls
  `DSCEngine.redeemCollateral(tokenAddress, amountCollateral)`
- No token approval is required
- After the transaction confirms, the dashboard refreshes:
  - Wallet balance for the redeemed token increases
  - Collateral breakdown table shows the reduced deposited balance and
    USD value
  - Health factor is recalculated
  - Total DSC debt remains unchanged

**Scenarios:**
- [x] **Scenario 1: Successful partial redemption**
  - Given the user has 2 WETH deposited and 0.5 WETH in wallet
  - When they redeem 1 WETH
  - Then the WETH wallet balance increases by 1, the deposited WETH
    balance decreases to 1, and health factor updates

- [x] **Scenario 2: Successful full redemption with no debt**
  - Given the user has 0.1 WBTC deposited and no DSC debt
  - When they redeem 0.1 WBTC
  - Then the deposited WBTC balance becomes 0, the wallet balance
    increases by 0.1 WBTC, and health factor shows "OK"


### User Story 43: Warn When Burn Would Leave Health Factor Broken
As a user with a health factor already below the minimum, I want to be
warned if burning the entered amount would still leave my health
factor below the threshold, so I can avoid a failed transaction.

**Acceptance Criteria:**
- The dApp calculates the projected health factor after burning (using
  `calculateHealthFactor`)
- If the projected health factor < `MIN_HEALTH_FACTOR`, a warning is
  shown
- The warning message explains that the burn would not be enough to
  restore health

**Scenarios:**
- [x] **Scenario 1: Burn insufficient to fix health factor**
  - Given the user has a health factor of 0.8 and debt of 1000 DSC
  - When they enter 100 DSC to burn (leaving health factor still < 1) and refresh the hf preview
  - Then a warning is displayed
- [x] **Scenario 2: Burn sufficient to restore health**
  - Given the user has a health factor of 0.8
  - When they enter an amount that brings health factor ≥ 1 and and refresh the hf preview
  - Then no warning is shown

---

## User Story 42: Handle User Rejection of Approval in Burn Flow
As a user, if I reject the DSC approval transaction, I expect the dApp
to cancel the burn gracefully and show a clear message.

**Acceptance Criteria:**
- When the user rejects the `approve` transaction, the dApp catches
  the error
- The burn does not proceed
- A status message is shown (e.g., "Approval cancelled")
- The UI remains consistent

**Scenarios:**
- **Scenario 1: User rejects approval**
  - Given the user clicks **Burn Only**
  - When the MetaMask approval prompt appears and the user clicks
    "Reject"
  - Then the dApp shows "Approval cancelled" and does not call
    `burnDsc`

---

## User Story 41: Handle User Rejection of Burn Transaction
As a user, if I approve the DSC spend but reject the burn transaction,
I expect the dApp to stop and inform me.

**Acceptance Criteria:**
- After successful approval, if the user rejects the `burnDsc`
  transaction, the dApp catches the error
- A status message is shown (e.g., "Transaction cancelled")
- The form remains filled

**Scenarios:**
- **Scenario 1: User rejects burn after approving**
  - Given the user approved the DSC spend
  - When the burn confirmation appears and the user rejects it
  - Then the dApp shows "Transaction cancelled" and the form remains
    filled

---

## User Story 40: Handle On-Chain Failure of Burn
As a user, if the burn transaction fails on-chain, I want to see a
descriptive error message.

**Acceptance Criteria:**
- If `burnDsc` reverts (e.g., `DSCEngine__BreaksHealthFactor` or
  `DSCEngine__NeedsMoreThanZero`), the dApp catches the error
- A descriptive error message is shown (e.g., "Transaction failed:
  health factor still too low")
- The UI does not crash; the user can try again

**Scenarios:**
- **Scenario 1: Burn reverts due to health factor**
  - Given the user attempts to burn an amount that still leaves health
    factor < 1 (and the frontend check was bypassed)
  - When the transaction reverts with `DSCEngine__BreaksHealthFactor`
  - Then the dApp displays the error reason and the form remains
    intact

---

## User Story 39: Handle Network Error During Burn
As a user, if a network error occurs while burning, I want to be
informed so I can retry.

**Acceptance Criteria:**
- If the RPC call throws a network error, the dApp catches it
- A status message is shown (e.g., "Network error, please try again")
- The form remains filled and the user can retry

**Scenarios:**
- **Scenario 1: Network error during approval**
  - Given the user clicks **Burn Only**
  - When the approval RPC call fails due to a network issue
  - Then the dApp shows "Network error, please try again" and the form
    remains intact
- **Scenario 2: Network error during burn**
  - Given the approval succeeded
  - When the `burnDsc` RPC call fails due to a network issue
  - Then the dApp shows "Network error, please try again" and the form
    remains intact

---

## User Story 38: Refresh Dashboard After Burn
As a user, after a successful burn, I want the dashboard to
automatically update all relevant data.

**Acceptance Criteria:**
- After the burn transaction is confirmed, `loadAppState()` is
  triggered
- Debt, DSC balance, and health factor are refreshed
- The updated values are displayed within a few seconds

**Scenarios:**
- **Scenario 1: Dashboard refreshes after burn**
  - Given the user burns 100 DSC
  - When the transaction is mined
  - Then debt decreases by 100, DSC balance decreases by 100, and
    health factor updates accordingly

## User Story 37: Prevent Burning Zero Amount
As a user, I want the dApp to prevent me from burning 0 DSC so I don't waste gas.

**Acceptance Criteria:**
- The **Burn Only** button is disabled when the burn amount is 0 or empty

**Scenarios:**
- **Scenario 1: Amount is 0**
  - Given the user enters 0 in the burn amount field
  - Then the burn button is disabled
- **Scenario 2: Amount is empty**
  - Given the burn amount field is blank
  - Then the burn button is disabled

---

## User Story 36: Prevent Burning with Insufficient DSC Balance
As a user, I want the dApp to prevent me from attempting to burn more
DSC than I hold in my wallet.

**Acceptance Criteria:**
- The **Burn Only** button is disabled when the entered amount > DSC
  wallet balance
- A warning message is shown (e.g., "Insufficient DSC balance")

**Scenarios:**
- **Scenario 1: Amount exceeds balance**
  - Given the user has 100 DSC in wallet
  - When they enter 150 DSC to burn
  - Then the burn button is disabled and a warning is displayed
- **Scenario 2: Amount equals balance (valid)**
  - Given the user has 100 DSC in wallet
  - When they enter 100 DSC
  - Then the burn button is enabled (provided other conditions are
    met)

---

## User Story 35: Prevent Burning More Than Debt
As a user, I want the dApp to prevent me from burning more DSC than my
current debt, because the contract would revert.

**Acceptance Criteria:**
- The **Burn Only** button is disabled when the entered amount > total
  DSC debt
- A warning message is shown (e.g., "Amount exceeds debt")

**Scenarios:**
- **Scenario 1: Amount exceeds debt**
  - Given the user has 200 DSC debt and 500 DSC in wallet
  - When they enter 300 DSC to burn
  - Then the burn button is disabled and a warning is displayed
- **Scenario 2: Amount equals debt (valid)**
  - Given the user has 200 DSC debt
  - When they enter 200 DSC
  - Then the burn button is enabled

---

## User Story 34: Burn DSC (Happy Path)
As a connected user with DSC debt and sufficient DSC balance, I want
to burn DSC to reduce my debt and improve my health factor.

**Acceptance Criteria:**
- The user enters a burn amount > 0 and ≤ their DSC wallet balance and
  ≤ their total DSC debt
- Clicking **Burn Only** triggers `approve` on the DSC token, then
  `burnDsc`
- After the transaction confirms, the dashboard refreshes:
  - `#total-dsc-debt` decreases by the burned amount
  - DSC wallet balance decreases by the burned amount
  - Health factor improves (increases) if collateral value unchanged

**Scenarios:**
- [x] **Scenario 1: Successful partial repayment**
  - Given the user has 500 DSC debt and 600 DSC in wallet
  - When they burn 200 DSC
  - Then debt becomes 300 DSC, wallet balance becomes 400 DSC, and
    health factor improves

- [x] **Scenario 2: Full repayment**
  - Given the user has 100 DSC debt and 100 DSC in wallet
  - When they burn 100 DSC
  - Then debt becomes 0, wallet balance becomes 0, and health factor
    shows "OK" (infinite)

---

## User Story 33: Prevent Deposit & Mint with Insufficient Balance
As a user, I want the dApp to prevent me from attempting a deposit and
mint that exceeds my wallet balance, so I don't waste gas on a failing
transaction.

**Acceptance Criteria:**
- The **Deposit & Mint** button is disabled when the entered
  collateral amount > wallet balance
- A warning message is shown (e.g., "Insufficient balance")

**Scenarios:**
- **Scenario 1: Amount exceeds balance**
  - Given the user has 1 WETH
  - When they enter 2 WETH in the collateral amount field
  - Then the **Deposit & Mint** button is disabled and a warning is
    displayed

- **Scenario 2: Amount equals balance (valid)**
  - Given the user has 1 WETH
  - When they enter 1 WETH and a positive mint amount
  - Then the **Deposit & Mint** button is enabled

---

## User Story 32: Prevent Deposit & Mint with Zero Amounts
As a user, I want the dApp to prevent me from depositing 0 collateral
or minting 0 DSC, so I don't waste gas on a meaningless transaction.

**Acceptance Criteria:**
- The **Deposit & Mint** button is disabled when either the collateral
  amount or the DSC mint amount is 0 or empty
- Optionally, a validation message is shown

**Scenarios:**
- **Scenario 1: Collateral amount is 0**
  - Given the user enters 0 in the collateral amount field and a
    positive DSC amount
  - Then the **Deposit & Mint** button is disabled

- **Scenario 2: DSC amount is 0**
  - Given the user enters a positive collateral amount and 0 in the
    DSC amount field
  - Then the **Deposit & Mint** button is disabled

- **Scenario 3: Both fields are empty**
  - Given both the collateral and DSC amount fields are blank
  - Then the **Deposit & Mint** button is disabled

---

## User Story 31: Warn When Deposit & Mint Would Break Health Factor
As a user, I want to be warned before depositing and minting if the
combined action would cause my health factor to drop below the
minimum, so that I can avoid a failed transaction.

**Acceptance Criteria:**
- The dApp calculates the projected health factor after the combined
  deposit and mint (using `calculateHealthFactor`)
- If the projected health factor < `MIN_HEALTH_FACTOR`, a warning is
  shown
- The warning message explains that the combined action would break
  the health factor

**Scenarios:**
- **Scenario 1: Combined action would break health factor**
  - Given the user has a health factor of 1.2
  - When they enter deposit and mint amounts that would drop the
    health factor below 1
  - Then a warning is displayed

- **Scenario 2: Combined action is safe**
  - Given the user has a health factor of 2.0
  - When they enter amounts that keep the health factor ≥ 1
  - Then no warning is shown

---

## User Story 30: Handle User Rejection of Approval in Deposit & Mint
As a user, if I reject the token approval transaction during the
deposit and mint flow, I expect the dApp to cancel the entire flow
gracefully and show a clear message.

**Acceptance Criteria:**
- When the user rejects the `approve` transaction in their wallet, the
  dApp catches the error
- The combined deposit and mint does not proceed
- A status message is shown (e.g., "Approval cancelled")
- The UI remains in a consistent state (no partial updates)

**Scenarios:**
- **Scenario 1: User rejects approval**
  - Given the user clicks **Deposit & Mint**
  - When the MetaMask approval prompt appears and the user clicks
    "Reject"
  - Then the dApp shows "Approval cancelled" and does not call
    `depositCollateralAndMintDsc`

---

## User Story 29: Handle User Rejection of Combined Transaction
As a user, if I approve the token but reject the combined deposit and
mint transaction, I expect the dApp to stop and inform me, without
leaving the UI in a broken state.

**Acceptance Criteria:**
- After successful approval, if the user rejects the
  `depositCollateralAndMintDsc` transaction, the dApp catches the
  error
- A status message is shown (e.g., "Transaction cancelled")
- The form remains filled

**Scenarios:**
- **Scenario 1: User rejects combined transaction after approving**
  - Given the user approved the token spend
  - When the combined transaction confirmation appears and the user
    rejects it
  - Then the dApp shows "Transaction cancelled" and the form remains
    filled

---

## User Story 28: Handle On-Chain Failure of Deposit & Mint
As a user, if the combined deposit and mint transaction fails
on-chain, I want to see a descriptive error message and understand
what happened.

**Acceptance Criteria:**
- If `depositCollateralAndMintDsc` reverts (e.g.,
  `DSCEngine__BreaksHealthFactor`, `DSCEngine__NeedsMoreThanZero`, or
  `DSCEngine__TokenNotAllowed`), the dApp catches the error
- A descriptive error message is shown (e.g., "Transaction failed:
  health factor too low")
- The UI does not crash; the user can try again

**Scenarios:**
- **Scenario 1: Combined transaction reverts due to health factor**
  - Given the user approved the token and the frontend check was
    bypassed
  - When the combined transaction reverts with
    `DSCEngine__BreaksHealthFactor`
  - Then the dApp displays the error reason and the form remains
    intact

- **Scenario 2: Combined transaction reverts due to zero amount**
  - Given the user approved the token
  - When the combined transaction reverts with
    `DSCEngine__NeedsMoreThanZero`
  - Then the dApp displays the error reason

---

## User Story 27: Handle Network Error During Deposit & Mint
As a user, if a network error occurs while depositing and minting, I
want to be informed so that I can retry later.

**Acceptance Criteria:**
- If the RPC call throws a network error (timeout, connection issue),
  the dApp catches it
- A status message is shown (e.g., "Network error, please try again")
- The form remains filled and the user can retry

**Scenarios:**
- **Scenario 1: Network error during approval**
  - Given the user clicks **Deposit & Mint**
  - When the approval RPC call fails due to a network issue
  - Then the dApp shows "Network error, please try again" and the form
    remains intact

- **Scenario 2: Network error during combined transaction**
  - Given the approval succeeded
  - When the `depositCollateralAndMintDsc` RPC call fails due to a
    network issue
  - Then the dApp shows "Network error, please try again" and the form
    remains intact

---

## User Story 26: Refresh Dashboard After Deposit & Mint
As a user, after a successful deposit and mint, I want the dashboard
to automatically update all relevant data so I can see my new position
without manual refresh.

**Acceptance Criteria:**
- After the combined transaction is confirmed, `loadAppState()` is
  triggered
- Wallet balances, collateral breakdown, health factor, and total debt
  are refreshed
- The updated values are displayed within a few seconds

**Scenarios:**
- **Scenario 1: Dashboard refreshes after deposit and mint**
  - Given the user deposits 1 WETH and mints 100 DSC
  - When the transaction is mined
  - Then the wallet balance decreases, collateral table shows the new
    deposit, debt increases, DSC balance increases, and health factor
    updates

---

## User Story 25: Deposit & Mint DSC (Happy Path)
As a connected user with WETH or WBTC, I want to deposit collateral
and mint DSC in a single transaction so that I can borrow against my
collateral with fewer steps.

**Acceptance Criteria:**
- The user selects a token, enters a collateral amount > 0 and a DSC
  mint amount > 0
- The dApp validates both amounts are valid (not exceeding balance,
  not zero)
- Clicking **Deposit & Mint** triggers `approve` then
  `depositCollateralAndMintDsc`
- After the combined transaction confirms, the dashboard refreshes:
  - Wallet balance decreases
  - Collateral breakdown table updates with new deposited balance and
    USD value
  - Total DSC debt increases by the minted amount
  - DSC wallet balance increases by the minted amount
  - Health factor updates accordingly

**Scenarios:**
- [x] **Scenario 1: Successful deposit and mint**
  - Given the user has 2 WETH and no existing deposits
  - When they deposit 1 WETH and mint 100 DSC
  - Then the wallet balance shows 1 WETH, collateral table shows 1
    WETH deposited, debt increases by 100 DSC, DSC balance increases
    by 100, and health factor updates

- [x] **Scenario 2: Deposit and mint when already having collateral and
  debt**
  - Given the user has 1 WETH deposited, 500 DSC debt, and 2 WETH in
    wallet
  - When they deposit another 0.5 WETH and mint 200 DSC
  - Then the deposited balance becomes 1.5 WETH, wallet balance
    becomes 1.5 WETH, debt becomes 700 DSC

---


## User Story 24: Handle User Rejection of Mint Transaction
As a user, if I reject the mint transaction in my wallet, I expect the
dApp to cancel gracefully and show a clear message.

**Acceptance Criteria:**
- When the user rejects the `mintDSC` transaction, the dApp catches
  the error
- A status message is shown (e.g., "Mint cancelled")
- The UI remains in a consistent state (no partial updates)

**Scenarios:**
- **Scenario 1: User rejects mint**
  - Given the user clicks "Mint DSC"
  - When the wallet confirmation appears and the user rejects it
  - Then the dApp shows "Mint cancelled" and the form remains filled

---

## User Story 23: Handle Mint Transaction Failure On-Chain
As a user, if the mint transaction fails on-chain (e.g., contract
revert), I want to see an error message and understand what happened.

**Acceptance Criteria:**
- If `mintDSC` reverts (e.g., `DSCEngine__BreaksHealthFactor` or
  `DSCEngine__NeedsMoreThanZero`), the dApp catches the error
- A descriptive error message is shown (e.g., "Transaction failed:
  health factor too low")
- The UI does not crash; the user can try again

**Scenarios:**
- **Scenario 1: Mint reverts due to health factor**
  - Given the user attempts to mint an amount that would break the
    health factor (and the frontend check was bypassed)
  - When the transaction reverts with `DSCEngine__BreaksHealthFactor`
  - Then the dApp displays the error reason and the form remains
    intact

---

## User Story 22: Handle Network Error During Mint
As a user, if a network error occurs while minting, I want to be
informed so that I can retry later.

**Acceptance Criteria:**
- If the RPC call throws a network error (timeout, connection issue),
  the dApp catches it
- A status message is shown (e.g., "Network error, please try again")
- The form remains filled and the user can retry

**Scenarios:**
- **Scenario 1: Network error during mint**
  - Given the user clicks "Mint DSC"
  - When the RPC call fails due to a network issue
  - Then the dApp shows "Network error, please try again" and the form
    remains intact

---

## User Story 21: Warn When Mint Would Break Health Factor
As a user, I want to be warned before minting if the transaction would
cause my health factor to drop below the minimum, so that I can avoid
a failed transaction.

**Acceptance Criteria:**
- The dApp calculates the projected health factor after minting (using
  `calculateHealthFactor`)
- If the projected health factor < `MIN_HEALTH_FACTOR`,  a warning is shown
- The warning message explains that the mint would break the health
  factor

**Scenarios:**
- [x] **Scenario 1: Mint would break health factor**
  - Given the user has a health factor of 1.2
  - When they enter an amount that would drop the health factor below
    1
  - Then the a warning is displayed
- [x] **Scenario 2: Mint is safe**
  - Given the user has a health factor of 2.0
  - When they enter an amount that keeps the health factor ≥ 1
  - Then  no warning is shown

---

## User Story 20: Prevent Minting Zero Amount
As a user, I want the dApp to prevent me from minting 0 DSC so that I
don't waste gas on a meaningless transaction.

**Acceptance Criteria:**
- The "Mint DSC" button is disabled when the amount is 0 or empty
- Optionally, a validation message is shown

**Scenarios:**
- **Scenario 1: Amount is 0**
  - Given the user enters 0 in the mint amount field
  - Then the mint button is disabled
- **Scenario 2: Amount is empty**
  - Given the mint amount field is blank
  - Then the mint button is disabled

---

## User Story 19: Mint DSC (Happy Path)
As a connected user with deposited collateral and a healthy position,
I want to mint DSC so that I can borrow against my collateral.

**Acceptance Criteria:**
- The user enters an amount > 0 and clicks "Mint DSC"
- The dApp calls `DSCEngine.mintDSC(amount)`
- After the transaction confirms, the dashboard refreshes:
  - `#total-dsc-debt` increases by the minted amount
  - Health factor decreases (if collateral value unchanged)
  - DSC wallet balance increases by the minted amount

**Scenarios:**
- [x] **Scenario 1: Successful mint**
  - Given the user has deposited collateral and health factor > 1
  - When they mint 100 DSC
  - Then the transaction succeeds, debt increases by 100, DSC balance
    increases by 100, and health factor updates accordingly

---

## User Story 18: Handle User Rejection of Approval
As a user, if I reject the token approval transaction, I expect the dApp to cancel the deposit flow gracefully and show a clear message.

**Acceptance Criteria:**
- When the user rejects the `approve` transaction in their wallet, the dApp catches the error
- The deposit does not proceed
- A status message is shown (e.g., "Approval cancelled")
- The UI remains in a consistent state (no partial updates)

**Scenarios:**
- **Scenario 1: User rejects approval**
  - Given the user clicks "Deposit Only"
  - When the MetaMask approval prompt appears and the user clicks "Reject"
  - Then the dApp shows "Approval cancelled" and does not call `depositCollateral`

---

## User Story 17: Handle User Rejection of Deposit
As a user, if I approve the token but reject the deposit transaction, I expect the dApp to stop and inform me, without leaving the UI in a broken state.

**Acceptance Criteria:**
- After successful approval, if the user rejects the `depositCollateral` transaction, the dApp catches the error
- A status message is shown (e.g., "Deposit cancelled")
- The approval remains (the user does not need to re-approve if they try again immediately)

**Scenarios:**
- **Scenario 1: User rejects deposit after approving**
  - Given the user approved the token spend
  - When the deposit confirmation appears and the user rejects it
  - Then the dApp shows "Deposit cancelled" and the form remains filled

---

## User Story 16: Handle Deposit Failure After Approval
As a user, if the deposit transaction fails on-chain (e.g., contract revert), I want to see an error message and understand what happened.

**Acceptance Criteria:**
- If `depositCollateral` reverts (e.g., `DSCEngine__TokenNotAllowed` or other reason), the dApp catches the error
- A descriptive error message is shown (e.g., "Transaction failed: …")
- The UI does not crash; the user can try again

**Scenarios:**
- **Scenario 1: Deposit reverts due to contract logic**
  - Given the user approved the token
  - When the deposit transaction reverts with a known error (e.g., `DSCEngine__NeedsMoreThanZero`)
  - Then the dApp displays the error reason and the form remains intact

---

## User Story 15: Prevent Zero Amount Deposit
As a user, I want the dApp to prevent me from depositing 0 tokens, because it would waste gas and make no sense.

**Acceptance Criteria:**
- The deposit buttons are disabled when the amount is 0 or empty
- Optionally, a validation message is shown

**Scenarios:**
- **Scenario 1: Amount is 0**
  - Given the user enters 0 in the collateral amount field
  - Then the deposit buttons are disabled
- **Scenario 2: Amount is empty**
  - Given the collateral amount field is blank
  - Then the deposit buttons are disabled

---

## User Story 14: Refresh Dashboard After Deposit
As a user, after a successful deposit, I want the dashboard to automatically update all relevant data so I can see my new position without manual refresh.

**Acceptance Criteria:**
- After the deposit transaction is confirmed, `loadAppState()` is triggered
- Wallet balances, collateral breakdown, health factor, and total debt are refreshed
- The updated values are displayed within a few seconds

**Scenarios:**
- **Scenario 1: Dashboard refreshes after deposit**
  - Given the user deposits 1 WETH
  - When the transaction is mined
  - Then the wallet balance decreases, collateral table shows the new deposit, and health factor updates if applicable

---

## User Story 13: Prevent Deposit with Insufficient Balance
As a user, I want the dApp to prevent me from attempting a deposit
that exceeds my wallet balance, so I don't waste gas on a failing
transaction.

**Acceptance Criteria:**
- The "Deposit Only" and "Deposit & Mint" buttons are disabled when
  the entered amount > wallet balance
- A warning message is shown (e.g., "Insufficient balance")

**Scenarios:**
- [x] **Scenario 1: Amount exceeds balance**
  - Given the user has 1 WETH
  - When they enter 2 WETH in the collateral amount field
  - Then the deposit buttons are disabled and a warning is displayed
- [x] **Scenario 2: Amount equals balance (valid)**
  - Given the user has 1 WETH
  - When they enter 1 WETH
  - Then the deposit buttons are enabled

---

## User Story 12: Deposit Collateral (Happy Path)
As a connected user with WETH or WBTC, I want to deposit collateral
into the DSCEngine so that I can improve my health factor or mint DSC
later.

**Acceptance Criteria:**
- The user selects a token (WETH/WBTC) and enters an amount > 0
- The dApp validates the amount does not exceed the wallet balance
- Clicking "Deposit Only" triggers `approve` then `depositCollateral`
- After both transactions confirm, the dashboard refreshes:
  - Wallet balance decreases
  - Collateral breakdown table updates with new deposited balance and
    USD value
  - Health factor and debt may update accordingly

**Scenarios:**
- [x] **Scenario 1: Successful deposit of WETH**
  - Given the user has 2 WETH and no existing deposits
  - When they deposit 1 WETH
  - Then the wallet balance shows 1 WETH, collateral table shows 1
    WETH deposited, and USD value is displayed
- [x] **Scenario 2: Successful deposit of WBTC**
  - Given the user has 0.5 WBTC
  - When they deposit 0.1 WBTC
  - Then the wallet balance decreases by 0.1 WBTC, collateral table
    shows 0.1 WBTC deposited
- [x] **Scenario 3: Deposit when already having collateral**
  - Given the user has 1 WETH deposited and 2 WETH in wallet
  - When they deposit another 0.5 WETH
  - Then the deposited balance becomes 1.5 WETH, wallet balance
    becomes 1.5 WETH

---

## User Story 11: Dashboard Resets on Disconnect
As a user who disconnects their wallet, I want all dashboard data to
be cleared so that no stale information is shown.

**Acceptance Criteria:**
- When the wallet disconnects, all dashboard values reset to `--`
- The health factor state resets to `data-state="unknown"`
- No contract calls are made after disconnect

---

## User Story 10: Dashboard Refreshes on Account Switch
As a connected user who switches accounts, I want the dashboard to
automatically refresh all displayed data for the new account.

**Acceptance Criteria:**
- When `connectedAccounts` changes, all dashboard data is re-fetched
- Placeholders are shown while data loads
- If fetching fails, an error status is shown and previous data is
  cleared

---

## User Story 9: View Collateral Breakdown
As a connected user, I want to see a breakdown of my deposited
collateral (amounts and USD values) so that I understand the
composition of my position.

**Acceptance Criteria:**
- Deposited WETH and WBTC balances are fetched via
  `DSCEngine.getCollateralBalanceOfUser(token, user)`
- USD values are fetched via `DSCEngine.getUsdValue(token, amount)`
- Values are displayed in the collateral table
  (`#collateral-weth-balance`, `#collateral-weth-usd`,
  `#collateral-wbtc-balance`, `#collateral-wbtc-usd`)
- The table updates when the user switches accounts

---

- [x] **Scenario 1: User has deposited both WETH and WBTC (happy
      path)**
  - **Given** the user is connected and has deposited WETH and WBTC
  - **When** the dashboard fetches collateral data
  - **Then** `getCollateralBalanceOfUser(token, user)` returns the
    deposited amounts for both tokens
  - **And** `getUsdValue(token, amount)` returns the USD values
  - **And** the values are displayed in `#collateral-weth-balance`,
    `#collateral-weth-usd`, `#collateral-wbtc-balance`,
    `#collateral-wbtc-usd`

---

- [x] **Scenario 2: User has deposited only one collateral type**
  - **Given** the user has deposited WETH but no WBTC
  - **When** the dashboard fetches collateral data
  - **Then** WETH row shows the balance and USD value
  - **And** WBTC row shows "0.00" for both balance and USD value

---

- [x] **Scenario 3: User has no deposits at all**
  - **Given** the user is connected but has never deposited any collateral
  - **When** the dashboard fetches collateral data
  - **Then** both WETH and WBTC rows display "0.00" for balance and USD value

---

- [x] **Scenario 4: Contract call fails (network error, RPC issue)**
    - **Given** the user is connected
    - **When** the dashboard attempts to fetch collateral balances
    - **And** one of the RPC calls throws an error
    - **Then** the corresponding table cells show `--`
    - **And** an error status message is displayed via `showStatus()`
    - **And** the rest of the dashboard does not crash

---

- [x] **Scenario 5: User switches accounts while data is loading**
    - **Given** the user is connected with account A and collateral fetches are in progress
    - **When** the user switches to account B before the calls resolve
    - **Then** the stale responses for account A are discarded
    - **And** new fetches are triggered for account B
    - **And** the collateral table reflects account B's deposits

---

- [x] **Scenario 6: User disconnects while data is loading**
    - **Given** the user is connected and collateral fetches are in progress
    - **When** the user disconnects their wallet before the calls resolve
    - **Then** the responses are discarded
    - **And** the collateral table cells reset to `--`
    - **And** no error is shown for the abandoned requests

---

- [x] **Scenario 7: Price feed returns stale data**
    - **Given** the user is connected and has collateral deposits
    - **When** the dashboard calls `getUsdValue(token, amount)`
    - **And** the underlying price feed's `staleCheckLatestRoundData` reverts with `OracleLib__StalePrice()`
    - **Then** the USD value cells show `--`
    - **And** an error status is displayed

## User Story 8: View Wallet Token Balances
As a connected user, I want to see my DSC, WETH, and WBTC wallet
balances on the dashboard so that I know what I have available to
deposit or repay.

**Acceptance Criteria:**
- Balances are fetched via `balanceOf(user)` on DSC, WETH, and WBTC
  contracts
- Values are displayed in `#dsc-balance`, `#weth-balance`, and
  `#wbtc-balance`
- Balances update when the user switches accounts

- [x] **Scenario 1: User has token balances (happy path)**
 - **Given** the user is connected and holds DSC, WETH, and WBTC in their wallet
 - **When** the dashboard fetches wallet balances
 - **Then** `balanceOf(user)` is called on the DSC, WETH, and WBTC contracts
 - **And** the values are displayed in `#dsc-balance`, `#weth-balance`, and `#wbtc-balance`

---

- [x] **Scenario 2: User has zero balances (edge case)**
 - **Given** the user is connected but holds no DSC, WETH, or WBTC
 - **When** the dashboard fetches wallet balances
 - **Then** `balanceOf(user)` returns `0` for all three tokens
 - **And** the UI displays "0.00" in `#dsc-balance`, `#weth-balance`, and `#wbtc-balance`

---

- [x] **Scenario 3: Contract call fails (network error, RPC issue)**
 - **Given** the user is connected
 - **When** the dashboard attempts to fetch wallet balances
 - **And** one of the `balanceOf` RPC calls throws an error
 - **Then** the corresponding balance element shows `--` or latest value
 - **And** an error status message is displayed via `showStatus()`
 - **And** the rest of the dashboard does not crash

---

- [x] **Scenario 4: User switches accounts while data is loading**
 - **Given** the user is connected with account A and balance fetches are in progress
 - **When** the user switches to account B before the calls resolve
 - **Then** the stale responses for account A are discarded
 - **And** new fetches are triggered for account B
 - **And** the balances displayed correspond to account B

---

- [x] **Scenario 5: User disconnects while data is loading**
 - **Given** the user is connected and balance fetches are in progress
 - **When** the user disconnects their wallet before the calls resolve
 - **Then** the responses are discarded
 - **And** `#dsc-balance`, `#weth-balance`, and `#wbtc-balance` reset to `--`
 - **And** no error is shown for the abandoned requests

---

## User Story 7: View Total DSC Debt
As a connected user, I want to see my total DSC debt on the dashboard
so that I understand my current borrowing position.

**Acceptance Criteria:**
- Total DSC minted is fetched from
  `DSCEngine.getAccountInformation(user)`
- The value is displayed in the `#total-dsc-debt` element
- If debt is 0, display "0.00"
- The value updates when the user switches accounts

- [x] **Scenario 1: User has an active debt position (happy path)**
  - **Given** the user is connected and has minted DSC
  - **When** the dashboard fetches account information
  - **Then** `DSCEngine.getAccountInformation(user)` returns
    `(totalDscMinted, collateralValueInUsd)` with `totalDscMinted > 0`
  - **And** the value is displayed in `#total-dsc-debt`

---

-- [x] **Scenario 2: User has zero debt (edge case)**
  - **Given** the user is connected but has never minted DSC, or has fully repaid
  - **When** the dashboard fetches account information
  - **Then** `DSCEngine.getAccountInformation(user)` returns `totalDscMinted = 0`
  - **And** the UI displays "0.00" in `#total-dsc-debt`

---

- [x] **Scenario 3: Contract call fails (network error, RPC issue)**
  - **Given** the user is connected
  - **When** the dashboard attempts to fetch account information
  - **And** the RPC call throws an error
  - **Then** `#total-dsc-debt` shows `--` or latest known value
  - **And** an error status message is displayed via `showStatus()`
  - **And** the rest of the dashboard does not crash

---

- [x] **Scenario 4: User switches accounts while data is loading**
 - **Given** the user is connected with account A and a
   `getAccountInformation` fetch is in progress
 - **When** the user switches to account B before the call resolves
 - **Then** the stale response for account A is discarded
 - **And** a new fetch is triggered for account B
 - **And** the debt displayed corresponds to account B

---

- [x] **Scenario 5: User disconnects while data is loading**
 - **Given** the user is connected and a `getAccountInformation` fetch is in progress
 - **When** the user disconnects their wallet before the call resolves
 - **Then** the response is discarded
 - **And** `#total-dsc-debt` resets to `--`
 - **And** no error is shown for the abandoned request

---

## User Story 6: View Account Health Factor
As a connected user, I want to see my current health factor on the
dashboard so that I know if my position is safe or at risk of
liquidation.

**Acceptance Criteria:**
- The health factor is fetched from `DSCEngine.getHealthFactor(user)`
  after connection
- The value is displayed in the `#health-factor` element
- If health factor < 1, a visual warning state is shown (e.g.,
  `data-state="danger"`)
- If the user has no debt, display "∞" or "N/A"
- The value updates when the user switches accounts

- [x] Scenario 1: User has a healthy position (happy path)
- **Given** the user is connected and has deposited collateral and
  minted DSC
- **When** the dashboard fetches the health factor
- **Then** `DSCEngine.getHealthFactor(user)` returns a value ≥ 1
- **And** the value is displayed in `#health-factor` with
  `data-state="safe"` (or no warning state)

---

- [x] Scenario 2: User has a risky position (health factor < 1)
- **Given** the user is connected and their collateral value has
  dropped below the liquidation threshold
- **When** the dashboard fetches the health factor
- **Then** `DSCEngine.getHealthFactor(user)` returns a value < 1
- **And** the value is displayed in `#health-factor` with
  `data-state="danger"`
- **And** a visual warning is shown (e.g., red color, pulsing, or
  icon)

---

- [x] Scenario 3: User has no debt (edge case)
- **Given** the user is connected and has deposited collateral but minted zero DSC
- **When** the dashboard fetches the health factor
- **Then** `DSCEngine.getHealthFactor(user)` returns a very large number or the maximum uint256 value
- **And** the UI displays "∞" or "N/A" instead of a raw number
- **And** `data-state` is set to something neutral like "safe" or "inactive"

---

- [x] Scenario 4: User has no deposits and no debt (fresh account)
- **Given** the user is connected but has never interacted with the protocol
- **When** the dashboard fetches the health factor
- **Then** `DSCEngine.getHealthFactor(user)` returns a value indicating no position (likely max uint256 or 0 depending on implementation)
- **And** the UI displays "∞" or "N/A"
- **And** no warning state is shown

---

- [x] Scenario 5: Contract call fails (network error, RPC issue)
- **Given** the user is connected
- **When** the dashboard attempts to fetch the health factor
- **And** the RPC call throws an error (timeout, rate limit, etc.)
- **Then** the `#health-factor` element shows `--` with `data-state="unknown"` or latest known value.
- **And** an error status message is displayed via `showStatus()`
- **And** the rest of the dashboard does not crash

---

- [x] Scenario 6: User switches accounts while data is loading
- **Given** the user is connected with account A and a health factor fetch is in progress
- **When** the user switches to account B before the call resolves
- **Then** the stale response for account A is discarded
- **And** a new fetch is triggered for account B
- **And** the health factor displayed corresponds to account B

---

- [x] Scenario 7: User disconnects while data is loading
- **Given** the user is connected and a health factor fetch is in progress
- **When** the user disconnects their wallet before the call resolves
- **Then** the response is discarded
- **And** the health factor resets to `--` with `data-state="unknown"`
- **And** no error is shown for the abandoned request

## User Story 5: React to account changes**  
As a connected user who switches accounts in my wallet, I want the
dApp to update the displayed address and state without requiring a
page reload.

*Acceptance Criteria:*  
- The dApp listens for the `accountsChanged` event.  
- When I switch accounts, the dApp updates the UI with the new address and recalculates relevant data.  
- If I disconnect all accounts, the dApp returns to the “not
  connected” state.
  
- [x] **Scenario 1: User switches to a different account while connected**
  - **Given** the user is connected with account A
  - **When** the user switches to account B in their wallet
  - **And** the wallet emits the `accountsChanged` event with `[accountB]`
  - **Then** the dApp updates the displayed address to account B
  - **And** recalculates any account‑dependent data (e.g., balances, health factor)
  - **And** the UI reflects the new account without a page reload

---

- [x] **Scenario 2: User disconnects all accounts**
- **Given** the user is connected with account A
- **When** the user disconnects all accounts in their wallet
- **And** the wallet emits the `accountsChanged` event with an empty array `[]`
- **Then** the dApp returns to the “not connected” state
- **And** the “Connect Wallet” button is shown again
- **And** all account‑specific data is cleared or hidden

---

- [x] **Scenario 3: User switches to an account that is already the current one**
- **Given** the user is connected with account A
- **When** the wallet emits the `accountsChanged` event with `[accountA]` (same account)
- **Then** the dApp does not unnecessarily re‑fetch data or reset the UI
- **And** the displayed address remains unchanged

---

- [x] **Scenario 4: `accountsChanged` fires while the dApp is in an unconnected state**
- **Given** the wallet is installed but no account is connected
- **When** the wallet emits the `accountsChanged` event (e.g., due to a wallet‑internal change)
- **Then** the dApp ignores the event or handles it gracefully without crashing
- **And** the UI remains in the “not connected” state

---

- [x] **Scenario 5: User switches accounts while on an unsupported network**
- **Given** the user is connected on an unsupported network with account A
- **When** the user switches to account B in their wallet
- **And** the wallet emits the `accountsChanged` event with `[accountB]`
- **Then** the dApp updates the displayed address to account B
- **And** the network mismatch warning remains visible
- **And** wallet‑dependent features stay disabled until the network is switched

---

- [x] **Scenario 6: Multiple accounts returned (e.g., wallet returns more than one)**
- **Given** the user is connected
- **When** the wallet emits the `accountsChanged` event with `[accountA, accountB]`
- **Then** the dApp uses the first account (`accountA`) as the active account
- **And** updates the UI accordingly

---

## User Story 4: Handle network mismatch**  
As a connected user on the wrong network, I want to be warned and
prompted to switch to the supported chain so that I can use the dApp
correctly.

*Acceptance Criteria:*  
- The dApp checks `eth_chainId` after connection.  
- If the chain ID is not supported, I see a warning and a button to trigger `wallet_switchEthereumChain`.  
- If I switch successfully, the dApp proceeds normally.

- [x] **Scenario 1: Connected on the supported network**
  - **Given** the wallet is INSTALLED and a supported chain ID is
    configured (e.g., `0xaa36a7` for Sepolia)
  - **When** the user connects their wallet
  - **Then** the dApp detects the chain ID matches the supported chain
  - **And** no warning is shown
  - **And** wallet‑dependent features are enabled

---

- [x] **Scenario 2: Connected on an unsupported network**
- **Given** the wallet is INSTALLED
- **When** the user connects their wallet on an unsupported chain (e.g., Ethereum mainnet `0x1`)
- **Then** the dApp detects the chain ID is not supported
- **And** a warning message is displayed (e.g., “Please switch to Sepolia”)
- **And** wallet‑dependent features are disabled or hidden

---

- [x] **Scenario 3: User successfully switches to the supported network**
- **Given** the user is connected on an unsupported network and sees the warning
- **When** the user clicks the “Switch Network” button
- **And** the dApp calls `wallet_switchEthereumChain` with the supported chain ID
- **And** the user approves the switch in their wallet
- **Then** the dApp detects the new chain ID is supported
- **And** the warning is removed
- **And** wallet‑dependent features are enabled

---

- [x] **Scenario 4: User rejects the network switch request**
- **Given** the user is connected on an unsupported network
- **When** the user clicks “Switch Network”
- **And** the dApp calls `wallet_switchEthereumChain`
- **And** the user rejects the request in their wallet
- **Then** the dApp catches the rejection error
- **And** remains in the warning state
- **And** shows a message like “Please switch to the supported network to continue”
- **And** does not crash or leave the UI in a broken state

---

- [x] **Scenario 5: User manually switches to an unsupported network while connected**
- **Given** the user is connected on the supported network
- **When** the user manually switches their wallet to an unsupported network
- **And** the wallet emits the `chainChanged` event
- **Then** the dApp detects the new unsupported chain ID
- **And** shows the network mismatch warning
- **And** disables wallet‑dependent features

---

- [x] **Scenario 6: User manually switches back to the supported network**
- **Given** the user was on an unsupported network and the warning is shown
- **When** the user manually switches their wallet to the supported network
- **And** the wallet emits the `chainChanged` event
- **Then** the dApp detects the new chain ID is supported
- **And** removes the warning
- **And** re‑enables wallet‑dependent features

---

## User Story 3: Automatic reconnection**  
As a returning user who previously connected, I want the dApp to
recognize my already-connected account.

*Acceptance Criteria:*  
- On page load, I click on the connect button  
- The dApp then shows my address and enables features immediately.  
- No “Connect Wallet” button is shown (or it changes to “Connected”).

---

## User Story 2: Connect already-installed wallet**  
As a user with a wallet installed but not yet connected, I want to
connect by clicking a “Connect Wallet” button so that I can access
dApp features.

*Acceptance Criteria:*  
- A “Connect Wallet” button is visible when the wallet is installed but no account is connected.  
- Clicking the button triggers `eth_requestAccounts`.  
- On success, my address is shown and dApp features are enabled.  
- If I reject the request, the dApp stays unconnected and shows an
  informative message.

- [x] **Scenario 1: Successful connection (happy path)**
- **Given** wallet is installed (`INSTALLED` state), no account connected
- **When** user clicks "Connect Wallet"
- **Then** `eth_requestAccounts` is called  
- User approves the MetaMask prompt  
- The dApp receives the account address, shows it in the UI, and enables dApp features

---

- [x] **Scenario 2: User rejects the connection request**
- **Given** wallet is installed, no account connected
- **When** user clicks "Connect Wallet" and then rejects the MetaMask prompt
- **Then** the dApp catches the rejection error  
- Stays in the unconnected state  
- Shows an informative message (e.g., "You need to connect to continue")

---

- [x] **Scenario 3: Wallet returns an empty accounts array**
- **Given** wallet is installed, user clicks "Connect Wallet"
- **When** `eth_requestAccounts` resolves but returns `[]` (e.g.,
  wallet is locked or user has no accounts)
- **Then** the dApp treats this as "not connected"  
- Shows the "Connect Wallet" button again, possibly with a hint to
  unlock or create an account

---

- [x] **Scenario 4: Unexpected error during connection**
- **Given** wallet is installed
- **When** `eth_requestAccounts` throws an unexpected error (e.g., provider error, network issue)
- **Then** the dApp catches the error gracefully  
- Shows a generic error message  
- Does not crash or leave the UI in a broken state

---

- [x] **Scenario 5: Double-click prevention**
- **Given** user clicks "Connect Wallet"
- **When** MetaMask prompt is already open and the user clicks again
- **Then** the dApp ignores the second click (e.g., disables the button while the request is in flight)  
- Avoids multiple concurrent `eth_requestAccounts` calls

---

## **User Story 1: Detect wallet installed**  
As a user, I want the dApp to automatically detect if I have a wallet
installed so that I know whether I can connect.

*Acceptance Criteria:*  
- If `window.ethereum` is present, the dApp considers a wallet installed.  
- If not present, a message is shown prompting me to install a wallet
  (e.g., MetaMask).
  
- [x] **Scenario 1: Wallet is installed (success)**

- **Given** the user opens the dApp and has a wallet extension (e.g.,
  MetaMask) installed in their browser.
- **When** the dApp loads and checks `window.ethereum`.
- **Then** `window.ethereum` is an object (truthy), and the dApp enters the “wallet installed” state.  
  - No wallet installation prompt is shown.  
  - The dApp may proceed to check connection status.

---

- [x] **Scenario 2: Wallet is not installed (failure)**

- **Given** the user opens the dApp in a browser without any wallet
  extension.
- **When** the dApp loads and checks `window.ethereum`.
- **Then** `window.ethereum` is `undefined`, and the dApp displays a message like “Please install MetaMask to continue.”  
  - Connection-related UI elements are hidden or disabled.  
  - The user cannot interact with wallet‑dependent features.

---

- [x] **Scenario 3: Other injected provider (edge case)**

- **Given** the user’s browser has a different injected provider (such
  as some mobile browsers or competing wallets) that exposes
  `window.ethereum`.
- **When** the dApp checks `window.ethereum`.
- **Then** the dApp treats it as “wallet installed” and proceeds with the same logic as Scenario 1.  
  - (For the MVP, any EIP‑1193 provider is acceptable; no special
    filtering is applied.)

---


- fuzz tests

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


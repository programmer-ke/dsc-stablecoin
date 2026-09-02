# todo


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

## User Story: Handle User Rejection of Mint Transaction
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

## User Story: Handle Mint Transaction Failure On-Chain
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

## User Story: Handle Network Error During Mint
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

## User Story: Warn When Mint Would Break Health Factor
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

## User Story: Prevent Minting Zero Amount
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


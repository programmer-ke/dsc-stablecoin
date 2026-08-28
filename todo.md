# todo

## User Story 9: View Collateral Breakdown
As a connected user, I want to see a breakdown of my deposited collateral (amounts and USD values) so that I understand the composition of my position.

**Acceptance Criteria:**
- Deposited WETH and WBTC balances are fetched via `DSCEngine.getCollateralBalanceOfUser(token, user)`
- USD values are fetched via `DSCEngine.getUsdValue(token, amount)`
- Values are displayed in the collateral table (`#collateral-weth-balance`, `#collateral-weth-usd`, `#collateral-wbtc-balance`, `#collateral-wbtc-usd`)
- The table updates when the user switches accounts

---

## User Story 10: Dashboard Refreshes on Account Switch
As a connected user who switches accounts, I want the dashboard to automatically refresh all displayed data for the new account.

**Acceptance Criteria:**
- When `connectedAccounts` changes, all dashboard data is re-fetched
- Placeholders are shown while data loads
- If fetching fails, an error status is shown and previous data is cleared

---

## User Story 11: Dashboard Resets on Disconnect
As a user who disconnects their wallet, I want all dashboard data to be cleared so that no stale information is shown.

**Acceptance Criteria:**
- When the wallet disconnects, all dashboard values reset to `--`
- The health factor state resets to `data-state="unknown"`
- No contract calls are made after disconnect

## User Story: Repay Debt

- [ ] **Scenario 6: User repays debt and dashboard refreshes**
 - **Given** the user has debt and the dashboard is displaying it
 - **When** the user repays some DSC (in another tab or via the dApp) and the dashboard re-fetches
 - **Then** the new, lower debt value is displayed in `#total-dsc-debt`
 - **And** if fully repaid, displays "0.00"

---

# in progress

# done

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


# todo

**User Story 5: Handle locked wallet**  
As a user with a wallet installed but locked, I want to be treated as
not connected until I unlock it, so that I can take the appropriate
action.

*Acceptance Criteria:*  
- If `eth_accounts` returns an empty array even though a wallet is installed, the dApp shows the “Connect Wallet” state.  
- No error is thrown; the interface simply prompts me to
  unlock/connect.

---

**User Story 6: React to account changes**  
As a connected user who switches accounts in my wallet, I want the
dApp to update the displayed address and state without requiring a
page reload.

*Acceptance Criteria:*  
- The dApp listens for the `accountsChanged` event.  
- When I switch accounts, the dApp updates the UI with the new address and recalculates relevant data.  
- If I disconnect all accounts, the dApp returns to the “not
  connected” state.

---

# in progress

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

**Scenario 5: User manually switches to an unsupported network while connected**
- **Given** the user is connected on the supported network
- **When** the user manually switches their wallet to an unsupported network
- **And** the wallet emits the `chainChanged` event
- **Then** the dApp detects the new unsupported chain ID
- **And** shows the network mismatch warning
- **And** disables wallet‑dependent features

---

**Scenario 6: User manually switches back to the supported network**
- **Given** the user was on an unsupported network and the warning is shown
- **When** the user manually switches their wallet to the supported network
- **And** the wallet emits the `chainChanged` event
- **Then** the dApp detects the new chain ID is supported
- **And** removes the warning
- **And** re‑enables wallet‑dependent features

---

**Scenario 7: Chain ID is returned in an unexpected format**
- **Given** the wallet is INSTALLED and the user connects
- **When** the wallet returns the chain ID in hexadecimal format (e.g., `0xaa36a7`)
- **Then** the dApp parses the value correctly
- **And** compares it against the supported chain ID without format mismatch errors


---

# done

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


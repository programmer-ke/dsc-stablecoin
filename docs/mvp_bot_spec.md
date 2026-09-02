To deploy a **minimum viable liquidation bot** for this protocol, you
need the following components:

---

### 1. **Data Monitoring (Off-chain)**
- **RPC endpoint** (e.g., Alchemy/Infura) to read contract state.
- **Polling loop** (e.g., every 5–10 seconds) that:
  - Fetches all users who have deposited collateral (you can maintain
    a list from events or scan `s_collateralDeposited`).
  - For each user, calls:
    - `getAccountInformation(user)` → `(totalDscMinted,
      collateralValueInUsd)`
    - `getHealthFactor(user)` → health factor
  - **Filter** users with `healthFactor < 1e18` (i.e.,
    `MIN_HEALTH_FACTOR`).

---

### 2. **Liquidation Decision Logic**
- For each undercollateralized user, compute:
  - `debtToCover` = the **minimum** of:
    - User's total DSC debt (`totalDscMinted`)
    - The amount of DSC the bot currently holds (or can acquire)
    - The maximum amount that still improves the user's health factor
      (per the protocol's math: `C > 1.1D` condition)
- **Choose collateral token** (WETH or WBTC) – the one with the
  highest liquidity / lowest gas cost.
- **Check bot's DSC balance** – if insufficient, either:
  - Buy DSC on a DEX (e.g., Uniswap) before liquidating, or
  - Skip until bot has enough DSC.

---

### 3. **Transaction Execution**
- **Private key** of the bot's wallet (stored securely, e.g., env
  variable).
- **Gas management**:
  - Use `eth_maxPriorityFeePerGas` / `eth_maxFeePerGas` (EIP-1559) or
    a gas station API.
  - Set a **max gas price** to avoid overpaying.
- **Call** `liquidate(collateralToken, user, debtToCover)` on the
  `DSCEngine` contract.
- **Handle reverts**:
  - `DSCEngine__HealthFactorOk` → user no longer liquidatable (skip).
  - `DSCEngine__HealthFactorNotImproved` → debt too large, reduce
    `debtToCover` and retry.
  - `DSCEngine__TransferFailed` → insufficient allowance/balance,
    handle.

---

### 4. **DSC Funding**
- The bot must **hold DSC** to pay off debt.
- Minimum viable approach: **pre-fund the bot with a fixed amount of
  DSC** (e.g., 10,000 DSC) and refill manually or via a script.
- Alternatively, integrate with a DEX to **flash-buy DSC** just before
  liquidation (more complex, not MVP).

---

### 5. **Error Handling & Logging**
- Log every liquidation attempt (user, debt, collateral, tx hash,
  success/failure).
- Retry logic with exponential backoff (e.g., 3 retries).
- Alerting (e.g., Telegram/email) on repeated failures or if bot runs
  out of DSC.

---

### 6. **Security & Reliability**
- **Run on a dedicated server** (e.g., AWS EC2, DigitalOcean) with
  99.9% uptime.
- **Use a separate wallet** with only enough ETH for gas and DSC for
  liquidations (limit risk).
- **Monitor bot health** (heartbeat endpoint or cron job).

---

### 7. **Optional (but recommended)**
- **Event listener** (WebSocket) instead of polling to react faster to
  price changes.
- **Price feed monitoring** – if Chainlink price drops, liquidations
  become more profitable; you can trigger liquidations immediately on
  price updates.

---

### **Minimum Viable Spec Summary**
| Component | Requirement |
|-----------|-------------|
| **RPC** | Mainnet RPC (Alchemy/Infura) |
| **Data** | Poll `getHealthFactor` for all users every 5–10s |
| **Logic** | Compute `debtToCover` (≤ user debt, ≤ bot DSC balance) |
| **Execution** | Call `liquidate()` with gas management |
| **Funding** | Pre-funded with DSC + ETH for gas |
| **Reliability** | Run on a server, log failures, retry |

That’s the absolute minimum. You can later add features like:
- **Flash loans** (Aave/Uniswap) to avoid holding DSC.
- **Multi-collateral liquidation** (liquidate both WETH and WBTC
  positions).
- **Gas optimization** (batching multiple liquidations in one tx).

### 1. **Dashboard / Account Overview**
**Purpose:** Show the user their current risk and liquidity at a
glance.

**Required Data (via view functions):**
- Collateral balance for each token (`getCollateralBalanceOfUser`)
- Total collateral value in USD (`getAccountCollateralValue`)
- Total DSC minted / debt (`getAccountInformation`)
- Current Health Factor (`getHealthFactor`)
- Token balances (`DSC.balanceOf`, `WETH.balanceOf`, `WBTC.balanceOf`)

**UI Elements:**
- Big number for Health Factor (alert if < 1)
- Table: Collateral breakdown (WETH/WBTC amounts + USD values)
- Card: Total DSC Debt
- Button links to Deposit / Redeem / Liquidate screens

---

### 2. **Borrow Screen (Deposit & Mint)**
**Purpose:** Allow users to deposit collateral and mint DSC.

**Actions (calls contract functions):**
- Approve WETH/WBTC spending on `DSCEngine` (if not approved)
- `depositCollateralAndMintDsc(weth, amountCollateral,
  amountDscToMint)` (or split into `depositCollateral` + `mintDSC`)

**UI Elements:**
- Token selector (WETH / WBTC)
- Collateral amount input
- Auto-calculated "Max DSC you can mint" (based on 200%
  overcollateralization)
- DSC amount input (with slider)
- Live health factor preview (simulate before submitting)
- Transaction status / error handling (especially
  `DSCEngine__BreaksHealthFactor`)

---

### 3. **Repay / Redeem Screen (Burn & Withdraw)**
**Purpose:** Allow users to burn DSC to pay down debt and/or withdraw
collateral.

**Actions (calls contract functions):**
- Approve DSC spending on `DSCEngine`
- `burnDsc(amount)` to reduce debt
- `redeemCollateralForDsc(weth, amountCollateral, amountDscToBurn)`
  (combined)
- Or separate `redeemCollateral` + `burnDsc`

**UI Elements:**
- Current Debt (DSC) and collateral balances
- Input for DSC to burn
- Input for collateral to withdraw
- Health factor simulation (withdrawing collateral or burning DSC
  changes HF)
- Error handling for `DSCEngine__BreaksHealthFactor` (can't withdraw
  too much)

---

### 4. **Liquidation Monitor (Utility Screen)**
**Purpose:** Let any user (like Bob) find and liquidate
undercollateralized positions.

**Actions (calls contract functions):**
- Input an address to check their health factor
- If HF < 1, input the `debtToCover`
- Call `liquidate(weth, userAddress, debtToCover)`

**UI Elements:**
- Address search bar
- Shows: User's collateral value, debt, health factor
- "Liquidate" button with amount input
- Shows expected collateral bonus (10% bonus)
- Error handling for `DSCEngine__HealthFactorOk` or
  `DSCEngine__HealthFactorNotImproved`

---

### **Infrastructure Needed (Not Screens)**
- **Connect Wallet** (MetaMask / WalletConnect / Web3Modal)
- **Network Switch** (must be on Mainnet, or chainId 1)
- **Token Approval Component** (handles the `approve()` transactions
  before deposits/burns)
- **Transaction Toast / Status** (show success/failure/revert reasons
  clearly)

**Summary:** The absolute MVP is **Dashboard + Borrow + Repay**. If
you want to make it actually functional (not just a personal vault),
add the **Liquidation Monitor** as a 4th screen, since that's the core
incentive mechanism that keeps the protocol solvent.

### Absolute Minimum Dependencies

For a **plain HTML + CSS + JavaScript** UI (no framework, no build
step), you only need:

---

### 1. **A Web3 Library – `ethers.js` (UMD Bundle)**

Load it via CDN in your HTML:

```html
<script src="https://cdn.ethers.io/lib/ethers-6.7.umd.min.js"></script>
```

This gives you everything needed to:
- Connect to MetaMask (`window.ethereum`)
- Read contract state (view functions)
- Send transactions (deposit, redeem, mint, burn, liquidate)
- Handle approvals

**No other JS library is required.**

---

### 2. **Contract ABIs (embedded in your JS)**

You need the ABIs for:

| Contract | Purpose |
|----------|---------|
| `DSCEngine` | Core protocol functions |
| `DecentralizedStableCoin` (DSC) | Check balance, approve, transfer |
| `ERC20` (for WETH/WBTC) | Check balance, approve |

You can copy the ABI JSON from your Foundry `out/` directory or
Hardhat artifacts, and paste it directly into your JavaScript file. No
need to fetch from a remote source.

---

### 3. **Mainnet Contract Addresses**

You need these hardcoded in your config:

```js
const config = {
  DSC_ENGINE: "0x...",  // your deployed engine
  DSC: "0x...",         // your deployed DSC
  WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  WBTC: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
};
```

---

### 4. **MetaMask (or any EIP-1193 injected wallet)**

You don't need `web3modal` or `wagmi`. For MVP, just use:

```js
await window.ethereum.request({ method: "eth_requestAccounts" });
```

and then:

```js
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();
```

---

### 5. **CSS/Fonts**

- Plain `style.css` (hand-written, no framework)
- Optional: Google Fonts (e.g., Inter) for nicer typography

---

### What You **Do NOT** Need

- ❌ React / Vue / Svelte
- ❌ Web3Modal / RainbowKit / ConnectKit
- ❌ Tailwind / Bootstrap (optional, but not required)
- ❌ IPFS / hosting backend (static hosting like GitHub Pages is
  enough)
- ❌ Node.js build tooling (Webpack/Vite) — just open `index.html` or
  serve the folder

---

### Minimal Page Structure

```
/index.html
/style.css
/app.js            (contains ABIs + all logic)
```

Load them with:

```html
<link rel="stylesheet" href="style.css" />
<script src="https://cdn.ethers.io/lib/ethers-6.7.umd.min.js"></script>
<script src="app.js"></script>
```

---

### Summary

**You only need `ethers.js`, ABIs, addresses, and MetaMask.** That's
the entire dependency list.

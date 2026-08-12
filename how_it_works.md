# How it works

The DSC stablecoin is pegged at $1. Users can deposit wETH/wBTC (ERC20
equivalents of the ETH and BTC) as collateral to mint DSC. A user can
only mint as much DSC as allows them to remain overcollateralized.

Currently, the user is required to be at least 200% overcollateralized,
meaning that they cannot mint more DSC than half the value of their
collateral.

## Example

Alice deposits 10 wETH. Chainlink says the price of wETH is $2000, so
Alice's collateral is worth $20,000.

Based on this collateral, Alice can mint at most $10,000 DSC. As long
as she doesn't exceed this, her health factor remains at or above 1,
which is the liquidation threshold.

Health factor is calculated as:

`health factor = collateral value * 0.5 / DSC Minted`

If she mints $5000 DSC, her health factor will be 2:

`health factor = 20000 * 0.5 / 5000 = 2`

If the health factor goes below 1, Alice can be liquidated.

Let's say Alice mints $10,000 DSC, her health factor will be exactly
1.

`health factor = 20000 * 0.5 / 10000 = 1`

If the price of wETH falls from $2000 to $1500, her collateral value
decreases to $15000 and her health factor drops below 1 - she becomes
liquidateable.

`health factor = 15000 * 0.5 / 10000 = 0.75`

Let's say Bob is monitoring the balances and notices that Alice can be
liquidated. He decides to pay off part of Alice's debt, and will in
return get the a share of Alice's collateral plus a 10% bonus.

Bob pays off $5000 DSC of Alice's debt. He receives 110% of the value
in wETH in return, i.e. $5500

`Bob's return = 1.1 * 5000 = 5500`

Alice's health factor has now improved:

```
new collateral = 15000 - 5500 = 9500

new debt amount = 10000 - 5000 = 5000

health factor = 9500 * 0.5 / 5000 = 0.95
```

Her health factor is still below 1, so Bob or anyone else can still
liquidate her as long as she is liquidateable.

To avoid getting liquidated, Alice can opt to either burn DSC,
reducing her debt, or deposit more collateral - both of which can push
her health factor above the liquidation threshold of 1.

Users can at any time burn DSC to reduce their debt and can withdraw
as much of their collateral as possible without dropping their health
factor below the liquidateable threshold.

This is how the various actors are incentivized to keep the protocol
solvent.

## Risks

### Stale Price halts the protocol

Currently, the protocol relies on Chainlink price feeds for an up to date
wETH and wBTC USD price.

If the price is more than 3 hours old, this check fails and the protocol
halts

### A Massive price drop breaks the protocol

If the price of collateral drops so low that the value of collateral
is less than the total DSC supply, the protocol cannot be fully backed
even with all positions liquidated. Each user will be left holding DSC
worth less than a $1.

### Inability to liquidate a user

If a user's collateral USD value is not greater than 110% of their
debt then they cannot be successfully liquidated because their
health factor does not improve, no matter how much of their debt is
covered.

#### Mathematically

Let:

- C - user's total collateral value
- D - their total debt
- X - debt to be covered by the liquidator

After liquidation:

- New debt: D - X
- New Collateral: C-1.1X

The health factor is proportional to C/D.

For the health factor to improve, the following must hold:

`C-1.1X / D - X > C / D`, which simplifies to `C > 1.1D`


# DeFi Stablecoin

A stablecoin DeFi protocol that powers a stablecoin pegged to the US
Dollar.

The stablecoin is an ERC20 token pegged to the US dollar that can be
used for micropayments such as with in-game currency or content
paywalls.

## How this is achieved

- **Relative stability**: Pegged to the US Dollar
  - Chainlink Pricefeed for near real time USD price
  - DSC minted against collateral USD value
- **Stability Mechanism**: Algorithmic decentralized minting/burning
  - Users may only mint stable coin with enough collateral
  - Actors incentivized to keep the protocol solvent by maintaining
    the required levels of collateral for minted coins
- **Exogenous Collateral**: The protocol is backed by assets outside
  of it whose prices determined independently by the market
  - Wrapped ETH (wETH)
  - Wrapped BTC (wBTC)

## Development

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/DeployDSC.s.sol:DeployDSC --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

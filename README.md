## Defi Stablecoin

1. Relative stability: Pegged to the US Dollar
  - Chainlink Pricefeed
  - Functionality to convert ETH & BTC  to USD
2. Stability Mechanism: Algorithmic decentralized minting/burning
  - Users may only mint stable coin with enough collateral
3. Collateral: Exogenous
  - wETH
  - WBTC

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
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
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

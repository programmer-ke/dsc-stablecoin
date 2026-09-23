// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        address deployerAddress;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 50_000e8;
    address public constant DEFAULT_ANVIL_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getEthMainnetConfig();
        } else if (block.chainid == 10) {
            activeNetworkConfig = getOptimismConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14,
            wbtc: 0x92f3B59a79bFf5dc60c0d59eA13a44D082B2bdFC,
            deployerAddress: vm.envAddress("SEPOLIA_DEPLOYER_ADDRESS")
        });
    }

    function getEthMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            wbtcUsdPriceFeed: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c,
            weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            wbtc: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            deployerAddress: vm.envAddress("ETH_DEPLOYER_ADDRESS")
        });
    }

    function getOptimismConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeed: 0x13e3Ee699D1909E989722E753853AE30b17e08c5,
            wbtcUsdPriceFeed: 0xD702DD976Fb76Fffc2D3963D037dfDae5b04E593,
            weth: 0x4200000000000000000000000000000000000006,
            wbtc: 0x68f180fcCe6836688e9084f035309E29Bf0A2095,
            deployerAddress: vm.envAddress("OP_DEPLOYER_ADDRESS")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8, 18);

        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        ERC20Mock wbtcMock = new ERC20Mock("WBTC", "WBTC", msg.sender, 1000e8, 8);
        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeed: address(ethUsdPriceFeed),
            wbtcUsdPriceFeed: address(btcUsdPriceFeed),
            weth: address(wethMock),
            wbtc: address(wbtcMock),
            deployerAddress: DEFAULT_ANVIL_ADDRESS
        });
    }
}

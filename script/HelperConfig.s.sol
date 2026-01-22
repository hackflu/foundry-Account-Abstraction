// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    NetworkConfig public config;

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant ANVIL_CHAIN_ID = 31337;
    address constant BURNER_WALLET = 0x0E6A032eD498633a1FB24b3FA96bF99bBBE4B754;
    address constant ANVIL_DEFAULT_KEY = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    mapping(uint256 chainId => NetworkConfig) public localNetworkConfig;

    constructor() {
        localNetworkConfig[ETH_SEPOLIA_CHAIN_ID] = _getSepoliaNetworkConfig();
        localNetworkConfig[ZKSYNC_SEPOLIA_CHAIN_ID] = _getZkSyncSeploiaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == ANVIL_CHAIN_ID) {
            return _getOrCreateAnvilEthConfig();
        }
        if (localNetworkConfig[chainId].entryPoint != address(0)) {
            return localNetworkConfig[chainId];
        }
        revert HelperConfig__InvalidChainId();
    }

    function _getSepoliaNetworkConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: BURNER_WALLET});
    }

    function _getZkSyncSeploiaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET});
    }

    function _getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (config.account != address(0)) {
            return config;
        }

        vm.startBroadcast(ANVIL_DEFAULT_KEY);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();
        // deploy mock entry point for the anvil chain
        config = NetworkConfig({entryPoint: address(entryPoint), account: ANVIL_DEFAULT_KEY});
        return config;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/Mockv3Aggregator.sol"; // Importing the mock aggregator contract

contract HelperConfig is Script {

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;  

    // This is a struct to hold the network configuration

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if(block.chainid == 11155111) { // Sepolia
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) { // Mainnet
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            revert("Unsupported network");
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) { 
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 // Sepolia ETH/USD price feed address
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // Mainnet ETH/USD price feed address
        });
        return ethConfig;
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {


        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE); // 2000 USD price for 1 ETH with 18 decimals
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed) // Use the address of the mock price feed
        });
        return anvilConfig;
    }
}
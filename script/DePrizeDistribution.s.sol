pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tables/DePrizeDistribution.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Using the $DEPRIZE testnet token for Sepolia: https://revnet.app/sepolia/50
        DePrizeDistribution dePrizeDistribution = new DePrizeDistribution("DEPRIZE_DISTRIBUTION", 0xf2a29F67fb5e6d7B9682591c0fD100d357dA85A7);

        vm.stopBroadcast();
    }
}

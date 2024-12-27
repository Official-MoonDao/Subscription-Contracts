pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SmartWalletChecker.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SmartWalletChecker sender = new SmartWalletChecker(true);

        vm.stopBroadcast();
    }
}

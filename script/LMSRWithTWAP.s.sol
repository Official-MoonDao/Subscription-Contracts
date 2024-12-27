pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LMSRWithTWAP.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        LMSRWithTWAP lmsrWithTWAP = new LMSRWithTWAP(0xCDb2D4d1B02AA041a7dB61159f2080cbfBB37671);

        vm.stopBroadcast();
    }
}


pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tables/MoonDaoDistributionTableland.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        citizenNftAddress = "0x31bD6111eDde8D8D6E12C8c868C48FF3623CF098"

        MoonDaoDistribution marketplace = new MoonDaoDistribution("");
        marketplace.setMoonDaoTeam(0x2a9135f02c35b07312A6D01c71B77ee683C59542);

        vm.stopBroadcast();
    }
}

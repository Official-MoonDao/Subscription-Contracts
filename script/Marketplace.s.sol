pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tables/MarketplaceTable.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MarketplaceTable marketplace = new MarketplaceTable("MARKETPLACE");
        marketplace.setMoonDaoTeam(0xEb9A6975381468E388C33ebeF4089Be86fe31d78);

        vm.stopBroadcast();
    }
}
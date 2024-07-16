pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tables/JobBoardTable.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        JobBoardTable jobBoardTable = new JobBoardTable("JOBBOARD");
        jobBoardTable.setMoonDaoTeam(0x8899116C9EaBD51eec2f73a9C55f08e4b281b0D6);

        vm.stopBroadcast();
    }
}
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tables/JobBoardTable.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        JobBoardTable jobBoardTable = new JobBoardTable("JOBBOARD");
        jobBoardTable.setMoonDaoTeam(0x2a9135f02c35b07312A6D01c71B77ee683C59542);

        vm.stopBroadcast();
    }
}
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/JBTeamProjectCreator.sol";
import "../src/tables/JBTeamProjectsTable.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address JB_CONTROLLER = 0x0000000000000000000000000000000000000000;
        address MOON_DAO_TEAM = 0x0000000000000000000000000000000000000000;
        address JB_TEAM_PROJECTS_TABLE = 0x0000000000000000000000000000000000000000;

        JBTeamProjectCreator jbTeamProjectCreator = new JBTeamProjectCreator(JB_CONTROLLER, MOON_DAO_TEAM, JB_TEAM_PROJECTS_TABLE);
        JBTeamProjectsTable jbTeamProjectsTable = new JBTeamProjectsTable("JBTeamProjectsTable", address(JBTeamProjectCreator));
        jbTeamProjectCreator.setJBTeamProjectsTable(address(jbTeamProjectsTable));

        vm.stopBroadcast();
    }
}

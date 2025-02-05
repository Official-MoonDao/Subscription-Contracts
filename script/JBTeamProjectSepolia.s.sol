pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/JBTeamProjectCreator.sol";
import "../src/tables/JBTeamProjectTable.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address JB_CONTROLLER = 0x7724a705d345c2a09B576E7D06dFd7ef2A62dae9;
        address JB_MULTI_TERMINAL = 0xfCFb61F66E44084b33ccBdA85e09665DDfEE64Eb;
        address MOON_DAO_TEAM = 0x21d2C4bEBd1AEb830277F8548Ae30F505551f961;
        address JB_TEAM_PROJECTS_TABLE = 0x0000000000000000000000000000000000000000;
        address MOON_DAO_TREASURY = 0x0724d0eb7b6d32AEDE6F9e492a5B1436b537262b;

        JBTeamProjectTable jbTeamProjectTable = new JBTeamProjectTable("JBTeamProjectTable", address(0));

        JBTeamProjectCreator jbTeamProjectCreator = new JBTeamProjectCreator(JB_CONTROLLER, JB_MULTI_TERMINAL, MOON_DAO_TEAM, JB_TEAM_PROJECTS_TABLE, MOON_DAO_TREASURY);

        jbTeamProjectTable.setJBTeamProjectCreator(address(jbTeamProjectCreator));
        jbTeamProjectCreator.setJBTeamProjectTable(address(jbTeamProjectTable));

        vm.stopBroadcast();
    }
}

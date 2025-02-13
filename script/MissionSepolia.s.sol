pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MissionCreator.sol";
import "../src/tables/MissionTable.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address JB_CONTROLLER = 0xd1F037EFeBF187A59520bcCe9D1DAbE5CcfAb2c3;
        address JB_MULTI_TERMINAL = 0x50fE7B6720901b74026aD714D9B393EDa7e39974;
        address MOON_DAO_TEAM = 0x21d2C4bEBd1AEb830277F8548Ae30F505551f961;
        address MISSION_PROJECTS_TABLE = 0x0000000000000000000000000000000000000000;
        address MOON_DAO_TREASURY = 0x0724d0eb7b6d32AEDE6F9e492a5B1436b537262b;

        MissionTable missionTable = new MissionTable("MissionTable", address(0));

        MissionCreator missionCreator = new MissionCreator(JB_CONTROLLER, JB_MULTI_TERMINAL, MOON_DAO_TEAM, MISSION_PROJECTS_TABLE, MOON_DAO_TREASURY);

        missionTable.setMissionCreator(address(missionCreator));
        missionCreator.setMissionTable(address(missionTable));

        vm.stopBroadcast();
    }
}

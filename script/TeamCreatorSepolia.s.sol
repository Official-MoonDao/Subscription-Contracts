// SPDX-License-Identifier: MIT

/*
Deploying a new Team Creator:
1. Run the script
2. (optional) Deploy a new whitelist contract and teamCreatorContract.setWhitelist()
3. teamContract.setMoonDaoCreatorAddress();
4. teamTableContract.setTeamCreator();
4. Transfer the controller hat to the new creator via hatsprotocol.xyz
5. Change hat eligibility to the new creator via etherscan
6. Set the new URI template for the team contract if function params have changed and you have updated the team table (teamTableContract.generateURITemplate)
*/

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreatorSepolia.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";


contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployerAddress = vm.addr(deployerPrivateKey);

        address TREASURY = 0x5DA2a965FDd9f20B1b9bd2bA033fCb1f50E75e18;
        address TEAM_ADDRESS = 0xEb9A6975381468E388C33ebeF4089Be86fe31d78;
        address TEAM_TABLE_ADDRESS = 0xD2b39d20203e3aB62970E1A8Ea658D948eF4e8a9;
        address WHITELIST_ADDRESS = 0x0000000000000000000000000000000000000000;

        IHats hats = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);
        uint256 moonDaoTeamAdminHatId = 0x0000018200020000000000000000000000000000000000000000000000000000;

        MoonDAOTeamCreator creator = new MoonDAOTeamCreator(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137, 0x0a3f85fa597B6a967271286aA0724811acDF5CD9, 0x97b5621E4CD8F403ab5b6036181982752DE3aC44, TEAM_ADDRESS, 0x3E5c63644E683549055b9Be8653de26E0B4CD36E, 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2, TEAM_TABLE_ADDRESS, WHITELIST_ADDRESS);

        creator.setOpenAccess(true);
        creator.setMoonDaoTeamAdminHatId(moonDaoTeamAdminHatId);

        vm.stopBroadcast();
    }
}

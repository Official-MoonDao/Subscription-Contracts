// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Project} from "../src/tables/Project.sol";
// import "../src/ERC5643.sol";
import {ProjectTeamCreator} from "../src/ProjectTeamCreator.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {ProjectTeam} from "../src/ProjectTeam.sol";



contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        address TREASURY = 0xAF26a002d716508b7e375f1f620338442F5470c0;

        address hatsAddress = 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137;
        address hatsModuleFactoryAddress = 0x0a3f85fa597B6a967271286aA0724811acDF5CD9;
        address hatsPassthroughAddress = 0x97b5621E4CD8F403ab5b6036181982752DE3aC44;
        address gnosisSingletonAddress = 0x3E5c63644E683549055b9Be8653de26E0B4CD36E;
        address gnosisSafeProxyFactoryAddress = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;

        IHats hats = IHats(hatsAddress);

        uint256 topHatId = hats.mintTopHat(deployerAddress, "", "");

        uint256 projectTeamAdminHatId = hats.createHat(topHatId, "ipfs://bafkreidfwizvfmfpzrl3p7kvy7a7pw3x4dzrdk5wckuxwtbs7a76hmcdn4", 1, TREASURY, TREASURY, true, "");

        ProjectTeam projectTeam = new ProjectTeam("ProjectTeam", "MDPT", TREASURY, hatsAddress);

        Project projectTable  = new Project("PROJECT");

        projectTable.setProjectTeam(address(projectTeam));

        ProjectTeamCreator creator = new ProjectTeamCreator(hatsAddress, hatsModuleFactoryAddress, hatsPassthroughAddress, address(projectTeam), gnosisSingletonAddress, gnosisSafeProxyFactoryAddress, address(projectTable));

        creator.setProjectTeamAdminHatId(projectTeamAdminHatId);
        projectTeam.setProjectTeamCreator(address(creator));

        hats.mintHat(projectTeamAdminHatId, address(creator));
        hats.changeHatEligibility(projectTeamAdminHatId, address(creator));

        // TODO (grinning face with sweat emoji)
        string memory uriTemplate = string.concat("SELECT+json_object%28%27id%27%2C+id%2C+%27name%27%2C+name%2C+%27description%27%2C+description%2C+%27image%27%2C+image%2C+%27attributes%27%2C+json_array%28json_object%28%27trait_type%27%2C+%27twitter%27%2C+%27value%27%2C+twitter%29%2C+json_object%28%27trait_type%27%2C+%27communications%27%2C+%27value%27%2C+communications%29%2C+json_object%28%27trait_type%27%2C+%27website%27%2C+%27value%27%2C+website%29%2C+json_object%28%27trait_type%27%2C+%27view%27%2C+%27value%27%2C+view%29%2C+json_object%28%27trait_type%27%2C+%27formId%27%2C+%27value%27%2C+formId%29%29%29+FROM+",projectTable.getTableName(),"+WHERE+id%3D");
		projectTeam.setURITemplate(uriTemplate);

        vm.stopBroadcast();
    }
}

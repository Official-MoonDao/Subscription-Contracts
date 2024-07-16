// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
// import "../src/ERC5643.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {MoonDAOTeam} from "../src/ERC5643.sol";
import {Whitelist} from "../src/Whitelist.sol";



contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address TREASURY = 0xAF26a002d716508b7e375f1f620338442F5470c0;

        Whitelist whitelist = new Whitelist();

        Whitelist discountList = new Whitelist();

        IHats hats = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);

        // uint256 topHatId = hats.mintTopHat(msg.sender, "", "");

        uint256 moonDaoTeamAdminHatId = hats.createHat(862718293348820473429344482784628181556388621521298319395315527974912, "", 1, 0xd1916F254866E4e70abA86F0dD668DD5942E032a, 0xd1916F254866E4e70abA86F0dD668DD5942E032a, true, "");

        MoonDAOTeam team = new MoonDAOTeam("MoonDaoTeam", "MDE", TREASURY, 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137, address(discountList));

        MoonDaoTeamTableland teamTable  = new MoonDaoTeamTableland("ENTITYTABLE");

        teamTable.setMoonDaoTeam(address(team));

        MoonDAOTeamCreator creator = new MoonDAOTeamCreator(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137, address(team), 0xfb1bffC9d739B8D520DaF37dF666da4C687191EA, 0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC, address(teamTable), address(whitelist));

        creator.setOpenAccess(true);

        creator.setMoonDaoTeamAdminHatId(moonDaoTeamAdminHatId);

        hats.mintHat(moonDaoTeamAdminHatId, address(creator));
        hats.changeHatEligibility(moonDaoTeamAdminHatId, address(creator));

        string memory uriTemplate = string.concat("SELECT+json_object%28%27id%27%2C+id%2C+%27name%27%2C+name%2C+%27description%27%2C+description%2C+%27image%27%2C+image%2C+%27attributes%27%2C+json_array%28json_object%28%27trait_type%27%2C+%27twitter%27%2C+%27value%27%2C+twitter%29%2C+json_object%28%27trait_type%27%2C+%27communications%27%2C+%27value%27%2C+communications%29%2C+json_object%28%27trait_type%27%2C+%27website%27%2C+%27value%27%2C+website%29%2C+json_object%28%27trait_type%27%2C+%27view%27%2C+%27value%27%2C+view%29%2C+json_object%28%27trait_type%27%2C+%27formId%27%2C+%27value%27%2C+formId%29%29%29+FROM+",teamTable.getTableName(),"+WHERE+id%3D");
		team.setURITemplate(uriTemplate);

        vm.stopBroadcast();
    }
}

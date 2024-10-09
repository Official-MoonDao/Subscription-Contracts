// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC5643.sol";
import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
import {JobBoardTable} from "../src/tables/JobBoardTable.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {TablelandDeployments} from "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
// import "../src/ERC5643.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {MoonDAOTeam} from "../src/ERC5643.sol";
import {Whitelist} from "../src/Whitelist.sol";

contract JobTest is Test {

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    JobBoardTable jobBoardTable;
    MoonDAOTeam erc5643;

    function setUp() public {
      //vm.deal(user1, 10 ether);
      //vm.deal(user2, 10 ether);

      vm.startPrank(user1);

        address TREASURY = 0xAF26a002d716508b7e375f1f620338442F5470c0;

        Whitelist whitelist = new Whitelist();

        Whitelist discountList = new Whitelist();

        IHats hats = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);

        uint256 topHatId = 11350137546870419353554813351635264513601237801889581014544619914919936;

        // uint256 topHatId = hats.mintTopHat(msg.sender, "", "");

        //uint256 moonDaoTeamAdminHatId = hats.createHat(topHatId, "ipfs://QmTp6pUATgqg5YoZ66CDEV1UUjhPVyn2t5KFvXvoobRpuV", 1, TREASURY, TREASURY, true, "");

        MoonDAOTeam team = new MoonDAOTeam("MoonDaoTeam", "MDE", TREASURY, 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137, address(discountList));

        // team.setDiscount(1000); //testing

        MoonDaoTeamTableland teamTable  = new MoonDaoTeamTableland("TEAMTABLE");

        teamTable.setMoonDaoTeam(address(team));

        MoonDAOTeamCreator creator = new MoonDAOTeamCreator(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137, address(team), 0x3E5c63644E683549055b9Be8653de26E0B4CD36E, 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2, address(teamTable), address(whitelist));

        // creator.setOpenAccess(true);

        //creator.setMoonDaoTeamAdminHatId(moonDaoTeamAdminHatId);
        team.setMoonDaoCreator(address(creator));

        //hats.mintHat(moonDaoTeamAdminHatId, address(creator));
        //hats.changeHatEligibility(moonDaoTeamAdminHatId, address(creator));
      //distribution = new Distribution("test");
      jobBoardTable = new JobBoardTable("test");

      //vm.startPrank(user4);

        jobBoardTable.insertIntoTable("test", "test", 0, "test");
        jobBoardTable.insertIntoTable("test", "test", 0, "test");
        jobBoardTable.insertIntoTable("test", "test", 0, "test");
        jobBoardTable.deleteFromTable(0,0);
        jobBoardTable.insertIntoTable("test", "test", 1, "test");

      vm.stopPrank();
    }

    function testInsertTable() public {
        console.log("currId", jobBoardTable.currId());
        console.log("currId", jobBoardTable.currId());
        console.log('idToTeamId', jobBoardTable.idToTeamId(0));
        jobBoardTable.updateTable(3, "test", "test", 1, "test");
    }
    function testUpdateTable() public {
        console.log('idToTeamId', jobBoardTable.idToTeamId(0));
        jobBoardTable.updateTable(0, "test", "test", 0, "test");
    }
}



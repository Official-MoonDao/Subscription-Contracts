// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC5643.sol";
import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
import {Project} from "../src/tables/Project.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {Whitelist} from "../src/Whitelist.sol";

contract ProjectTest is Test {

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    Project project;

    function setUp() public {
      //vm.deal(user1, 10 ether);
      //vm.deal(user2, 10 ether);
      project = new Project("test");
      console.log(address(project));

      //vm.startPrank(user4);


      //vm.stopPrank();
    }

    function testUpdateTable() public {
        project.insertIntoTable("test", 2021, 1, 100, "proposal", "final", "allocation");
    }
}


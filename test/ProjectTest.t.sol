// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC5643.sol";
import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
import {Project} from "../src/tables/Project.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {TablelandDeployments} from "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {Whitelist} from "../src/Whitelist.sol";

contract ProjectTest is Test {

    address user1 = address(0x1);
    Project project;

    function setUp() public {

      vm.startPrank(user1);

      project = new Project("test");
      console.log(address(project));

      vm.stopPrank();
    }

    function testInsertTable() public {
        project.insertIntoTable("test", 2021, 1, 100, "proposal", "link", "final", "link", "allocation 0", 1);
    }
}


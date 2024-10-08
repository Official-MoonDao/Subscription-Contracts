// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC5643.sol";
import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
import {Distribution} from "../src/tables/Distribution.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {TablelandDeployments} from "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {Whitelist} from "../src/Whitelist.sol";

contract DistributionTest is Test {

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    Distribution distribution;

    function setUp() public {
      //vm.deal(user1, 10 ether);
      //vm.deal(user2, 10 ether);

      vm.startPrank(user1);

      distribution = new Distribution("test");
      console.log(address(distribution));

      //vm.startPrank(user4);


      vm.stopPrank();
    }

    function testInsertTable() public {
        distribution.insertIntoTable(1, 2021, 'test distribution 0');
    }
    function testUpdateTable() public {
        distribution.updateTableCol(1, 2021, 'test distribution 1');
    }
}


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC5643.sol";
import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
import {TeamRowController} from "../src/tables/TeamRowController.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {Whitelist} from "../src/Whitelist.sol";

contract ERC5643Test is Test {
    event SubscriptionUpdate(uint256 indexed tokenId, uint64 expiration);

    address user1 = address(0x43b8880beE7fAb93F522AC8e121FF13fB77AF711);
    address user2 = address(0x2);
    address user3 = address(0x3);
    address user4 = address(0xd1916F254866E4e70abA86F0dD668DD5942E032a);
    uint256 tokenId = 0;
    uint256 tokenId2 = 1;
    uint256 tokenId3= 2;
    string uri = "https://test.com";
    MoonDAOTeam erc5643;
    MoonDAOTeamCreator creator;
    MoonDaoTeamTableland table;

    function setUp() public {
      vm.deal(user1, 10 ether);
      vm.deal(user2, 10 ether);

      vm.startPrank(user4);

      IHats hats = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);

      Whitelist whitelist = new Whitelist();

      Whitelist discountList = new Whitelist();
      table = new MoonDaoTeamTableland("MoonDaoTeamTable");

      uint256 moonDaoTeamAdminHatId = hats.createHat(862718293348820473429344482784628181556388621521298319395315527974912, "", 1, user4, 0xd1916F254866E4e70abA86F0dD668DD5942E032a, true, "");
      // controller = new TeamRowController(address(table));

      erc5643 = new MoonDAOTeam("erc5369", "ERC5643", 0xd1916F254866E4e70abA86F0dD668DD5942E032a, 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137, address(discountList));
      creator = new MoonDAOTeamCreator(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137, address(erc5643), 0x3E5c63644E683549055b9Be8653de26E0B4CD36E, 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2, address(table), address(whitelist));

      creator.setOpenAccess(true);

      table.setMoonDaoTeam(address(erc5643));

      creator.setMoonDaoTeamAdminHatId(moonDaoTeamAdminHatId);

      hats.mintHat(moonDaoTeamAdminHatId, address(creator));
      hats.changeHatEligibility(moonDaoTeamAdminHatId, address(creator));

      vm.stopPrank();
    }

    function testMint() public {
      vm.prank(user1);
      creator.createMoonDAOTeam{value: 0.1 ether}("", "","name", "bio", "image", "twitter", "communications", "website", "view", "formId");
    }

    function testUpdateTable() public {
      vm.prank(user1);
      (uint256 topHatId, uint256 hatId) = creator.createMoonDAOTeam{value: 0.1 ether}("", "", "name", "bio", "image", "twitter", "communications", "website", "view", "formId");

      // vm.prank(user4);
      // table.updateTable(0, hatId, "name", "bio", "image", "twitter", "communications", "website", "view", "formId");
      bool isAdmin = erc5643.isManager(0, user1);
      assertTrue(isAdmin);

      bool isAdmin2 = erc5643.isManager(0, user4);
      assertFalse(isAdmin2);
    }
}
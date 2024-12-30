// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ProjectTeam.sol";
import "../src/GnosisSafeProxyFactory.sol";
import {PassthroughModule} from "../src/PassthroughModule.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {Hats} from "@hats/Hats.sol";
import {HatsModuleFactory} from "@hats-module/HatsModuleFactory.sol";
import {deployModuleFactory} from "@hats-module/utils/DeployFunctions.sol";
import {ProjectTeamCreator} from "../src/ProjectTeamCreator.sol";
import {Project} from "../src/tables/Project.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {Hats} from "@hats/Hats.sol";

contract CreatorTest is Test {
    event SubscriptionUpdate(uint256 indexed tokenId, uint64 expiration);

    bytes32 internal constant SALT = bytes32(abi.encode(0x4a75)); // ~ H(4) A(a) T(7) S(5)

    address user1 = address(0x43b8880beE7fAb93F522AC8e121FF13fB77AF711);
    address user2 = address(0x2);
    address user3 = address(0x3);
    address user4 = address(0xd1916F254866E4e70abA86F0dD668DD5942E032a);
    uint256 tokenId = 0;
    uint256 tokenId2 = 1;
    uint256 tokenId3= 2;
    string uri = "https://test.com";
    address TREASURY = user4;
    ProjectTeam team;
    Project table;
    ProjectTeamCreator creator;

    function setUp() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.startPrank(user4);


        Hats hatsBase = new Hats("", "");
        IHats hats = IHats(address(hatsBase));
        HatsModuleFactory hatsFactory = deployModuleFactory(hats, SALT, "");
        PassthroughModule passthrough = new PassthroughModule("");
        address gnosisSafeAddress = address(0x0165878A594ca255338adfa4d48449f69242Eb8F);
        GnosisSafeProxyFactory proxyFactory = new GnosisSafeProxyFactory();


        Whitelist whitelist = new Whitelist();
        Whitelist discountList = new Whitelist();

        table = new Project("PROJECT");

        team = new ProjectTeam("PROJECT", "MDPT", user4, address(hats), address(discountList));
        creator = new ProjectTeamCreator(address(hatsBase), address(hatsFactory), address(passthrough), address(team), gnosisSafeAddress, address(proxyFactory), address(table), address(whitelist));

        creator.setOpenAccess(true);

        table.setProjectTeam(address(team));
        uint256 topHatId = hats.mintTopHat(user4, "", "");
        uint256 projectTeamAdminHatId = hats.createHat(topHatId, "", 1, TREASURY, TREASURY, true, "");

        creator.setProjectTeamAdminHatId(projectTeamAdminHatId);
        team.setProjectTeamCreator(address(creator));

        hats.mintHat(projectTeamAdminHatId, address(creator));
        vm.stopPrank();
    }

    function testMint() public {
        address[] members = address[](2);
        members[0] = user3;
        members[1] = user4;
        vm.prank(user1);
        creator.createProjectTeam{value: 0 ether}(uri, uri, uri, "title",4,2024, 169, "IPFS_HASH", members);
    }




}

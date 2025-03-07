// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {JBRuleset} from "@nana-core/structs/JBRuleset.sol";
import {JBRulesetMetadata} from "@nana-core/structs/JBRulesetMetadata.sol";
import {IJBDirectory} from "@nana-core/interfaces/IJBDirectory.sol";
import {MoonDAOTeam} from "../src/ERC5643.sol";
import {GnosisSafeProxyFactory} from "../src/GnosisSafeProxyFactory.sol";
import {MissionCreator} from "../src/MissionCreator.sol";
import {MissionTable} from "../src/tables/MissionTable.sol";
import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
import {TeamRowController} from "../src/tables/TeamRowController.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {PassthroughModule} from "../src/PassthroughModule.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {Hats} from "@hats/Hats.sol";
import {HatsModuleFactory} from "@hats-module/HatsModuleFactory.sol";
import {deployModuleFactory} from "@hats-module/utils/DeployFunctions.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {IJBTerminal} from "@nana-core/interfaces/IJBTerminal.sol";
import { JBConstants } from "@nana-core/libraries/JBConstants.sol";
import {IJBController} from "@nana-core/interfaces/IJBController.sol";

contract MissionTest is Test {

    address zero = address(0);
    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    address user4 = address(0x4);
    address TREASURY = user4;

    bytes32 internal constant SALT = bytes32(abi.encode(0x4a75));

    MoonDAOTeam moonDAOTeam;
    MoonDAOTeamCreator moonDAOTeamCreator;
    MoonDaoTeamTableland moonDAOTeamTable;

    MissionCreator missionCreator;
    MissionTable missionTable;
    IJBDirectory jbDirectory;

    function setUp() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);

        vm.startPrank(user1);

        Hats hatsBase = new Hats("", "");
        IHats hats = IHats(address(hatsBase));
        HatsModuleFactory hatsFactory = deployModuleFactory(hats, SALT, "");
        PassthroughModule passthrough = new PassthroughModule("");
        address gnosisSafeAddress = address(0x0165878A594ca255338adfa4d48449f69242Eb8F);
        GnosisSafeProxyFactory proxyFactory = new GnosisSafeProxyFactory();

        Whitelist teamWhitelist = new Whitelist();
        Whitelist teamDiscountList = new Whitelist();

        moonDAOTeamTable = new MoonDaoTeamTableland("MoonDaoTeamTable");
        moonDAOTeam = new MoonDAOTeam("erc5369", "ERC5643", TREASURY, address(hatsBase), address(teamDiscountList));
        moonDAOTeamCreator = new MoonDAOTeamCreator(address(hatsBase), address(hatsFactory), address(passthrough), address(moonDAOTeam), gnosisSafeAddress, address(proxyFactory), address(moonDAOTeamTable), address(teamWhitelist));
        jbDirectory = IJBDirectory(0xEaF625c6ff600D34C557B2d9492d48678F3CCa3D);


        uint256 topHatId = hats.mintTopHat(user1, "", "");
        uint256 moonDAOTeamAdminHatId = hats.createHat(topHatId, "", 1, TREASURY, TREASURY, true, "");

        moonDAOTeamCreator.setOpenAccess(true);
        moonDAOTeamTable.setMoonDaoTeam(address(moonDAOTeam));
        moonDAOTeamCreator.setMoonDaoTeamAdminHatId(moonDAOTeamAdminHatId);
        moonDAOTeam.setMoonDaoCreator(address(moonDAOTeamCreator));
        hats.mintHat(moonDAOTeamAdminHatId, address(moonDAOTeamCreator));
        address jbControllerAddress = address(0xFd2B5dBc4251Eed629742B51292A05FFf5D8BDd8);
        address jbMultiTerminalAddress = address(0x0BC7A37F6d6748af95030Ba36E877DcF0F7f7425);
        address jbProjectsAddress = address(0x39a7dDa0F1b3bee0c9470eeFB4A18BE27092Ec30);
        address jbDirectoryAddress = address(0xEaF625c6ff600D34C557B2d9492d48678F3CCa3D);
        address jbTerminalStoreAddress = address(0x74EC07145ee332391cd7241d5F312A3586388064);

        missionCreator = new MissionCreator(jbControllerAddress, jbMultiTerminalAddress, jbProjectsAddress, jbDirectoryAddress, jbTerminalStoreAddress, address(moonDAOTeam), zero, user1);
        missionTable = new MissionTable("TestMissionTable", address(missionCreator));
        missionCreator.setMissionTable(address(missionTable));

        vm.stopPrank();
    }

    function testCreateTeamProject() public {
        vm.startPrank(user1);
        moonDAOTeamCreator.createMoonDAOTeam{value: 0.555 ether}("", "", "","name", "bio", "image", "twitter", "communications", "website", "view", "formId", new address[](0));
        uint256 missionId = missionCreator.createMission(
           0,
           user1,
           "",
           0,
           block.timestamp + 1 days,
           1_000_000_000_000_000_000_000_000,
           2_000_000_000_000_000_000_000_000,
           true,
           "TEST TOKEN",
           "TEST",
           "This is a test project"
        );
        uint256 projectId = missionCreator.missionIdToProjectId(missionId);
        IJBController jbController = IJBController(address(jbDirectory.controllerOf(projectId)));
        //function currentRulesetOf(uint256 projectId)
    //external
    //view
    //returns (JBRuleset memory ruleset, JBRulesetMetadata memory metadata);
        JBRuleset memory ruleset;
        JBRulesetMetadata memory metadata;
        (ruleset, metadata) = jbController.currentRulesetOf(projectId);
        assertEq(ruleset.cycleNumber, 1);
        IJBTerminal terminal = jbDirectory.primaryTerminalOf(projectId, JBConstants.NATIVE_TOKEN);
        terminal.pay(
            projectId,
            JBConstants.NATIVE_TOKEN,
            1_000_000_000_000_000_000,
            user1,
            0,
            "",
            new bytes(0)
        );
        (ruleset, metadata) = jbController.currentRulesetOf(projectId);
        assertEq(ruleset.cycleNumber, 2);
        vm.stopPrank();
    }

    function testSetJBController() public {
        vm.prank(user1);
        missionCreator.setJBController(address(0));
    }

    function testSetJBMultiTerminal() public {
        vm.prank(user1);
        missionCreator.setJBMultiTerminal(address(0));
    }

    function testSetMoonDAOTreasury() public {
        vm.prank(user1);
        missionCreator.setMoonDAOTreasury(address(0));
    }

    function testSetMoonDAOTeam() public {
        vm.prank(user1);
        missionCreator.setMoonDAOTeam(address(moonDAOTeam));
    }

    function testSetMissionTable() public {
        vm.prank(user1);
        missionCreator.setMissionTable(address(missionTable));
    }

}


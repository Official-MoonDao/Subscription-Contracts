// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {JBRuleset} from "@nana-core/structs/JBRuleset.sol";
import {IJBRulesets} from "@nana-core/interfaces/IJBRulesets.sol";
import {JBApprovalStatus} from "@nana-core/enums/JBApprovalStatus.sol";
import {IJBRulesetApprovalHook} from "@nana-core/interfaces/IJBRulesetApprovalHook.sol";
import {JBRulesetMetadata} from "@nana-core/structs/JBRulesetMetadata.sol";
import {IJBDirectory} from "@nana-core/interfaces/IJBDirectory.sol";
import {MoonDAOTeam} from "../src/ERC5643.sol";
import {GnosisSafeProxyFactory} from "../src/GnosisSafeProxyFactory.sol";
import {MissionCreator} from "../src/MissionCreator.sol";
import {MissionTable} from "../src/tables/MissionTable.sol";
import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
import {TeamRowController} from "../src/tables/TeamRowController.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {LaunchPadPayHook} from "../src/LaunchPadPayHook.sol";
import {PassthroughModule} from "../src/PassthroughModule.sol";
import {IHats} from "@hats/Interfaces/IHats.sol";
import {Hats} from "@hats/Hats.sol";
import {HatsModuleFactory} from "@hats-module/HatsModuleFactory.sol";
import {deployModuleFactory} from "@hats-module/utils/DeployFunctions.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {IJBTerminal} from "@nana-core/interfaces/IJBTerminal.sol";
import {IJBTokens} from "@nana-core/interfaces/IJBTokens.sol";
import { JBConstants } from "@nana-core/libraries/JBConstants.sol";
import {IJBController} from "@nana-core/interfaces/IJBController.sol";
import {IJBTerminalStore} from "@nana-core/interfaces/IJBTerminalStore.sol";

contract MissionTest is Test {

    address zero = address(0);
    address user1 = address(0x1);
    address user4 = address(0x4);
    address TREASURY = user4;

    bytes32 internal constant SALT = bytes32(abi.encode(0x4a75));

    MoonDAOTeam moonDAOTeam;
    MoonDAOTeamCreator moonDAOTeamCreator;
    MoonDaoTeamTableland moonDAOTeamTable;

    MissionCreator missionCreator;
    MissionTable missionTable;
    IJBDirectory jbDirectory;
    IJBTerminalStore jbTerminalStore;
    IJBRulesets jbRulesets;
    IJBTokens jbTokens;


    function setUp() public {
        vm.deal(user1, 10 ether);

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
        jbDirectory = IJBDirectory(0x0bC9F153DEe4d3D474ce0903775b9b2AAae9AA41);


        uint256 topHatId = hats.mintTopHat(user1, "", "");
        uint256 moonDAOTeamAdminHatId = hats.createHat(topHatId, "", 1, TREASURY, TREASURY, true, "");

        moonDAOTeamCreator.setOpenAccess(true);
        moonDAOTeamTable.setMoonDaoTeam(address(moonDAOTeam));
        moonDAOTeamCreator.setMoonDaoTeamAdminHatId(moonDAOTeamAdminHatId);
        moonDAOTeam.setMoonDaoCreator(address(moonDAOTeamCreator));
        hats.mintHat(moonDAOTeamAdminHatId, address(moonDAOTeamCreator));
        address jbControllerAddress = address(0xb291844F213047Eb9e1621AE555B1Eae6700d553);
        address jbMultiTerminalAddress = address(0xDB9644369c79C3633cDE70D2Df50d827D7dC7Dbc);
        address jbProjectsAddress = address(0x0b538A02610d7d3Cc91Ce2870F423e0a34D646AD);

        address jbTerminalStoreAddress = address(0x6F6740ddA12033ca9fBAA56693194E38cfD36827);
        address jbPermissionsAddress = address(0xF5CA295dc286A176E35eBB7833031Fd95550eb14);
        jbRulesets = IJBRulesets(0xDA86EeDb67C6C9FB3E58FE83Efa28674D7C89826);
        jbTerminalStore = IJBTerminalStore(jbTerminalStoreAddress);
        jbTokens = IJBTokens(0xA59e9F424901fB9DBD8913a9A32A081F9425bf36);

        missionCreator = new MissionCreator(jbControllerAddress, jbMultiTerminalAddress, jbProjectsAddress, jbTerminalStoreAddress, address(moonDAOTeam), zero, user1);
        missionTable = new MissionTable("TestMissionTable", address(missionCreator));
        missionCreator.setMissionTable(address(missionTable));

        vm.stopPrank();
    }

    function testCreateTeamProject() public {
        vm.startPrank(user1);
        uint256 deadline = block.timestamp + 2 days;
        moonDAOTeamCreator.createMoonDAOTeam{value: 0.555 ether}("", "", "","name", "bio", "image", "twitter", "communications", "website", "view", "formId", new address[](0));
        uint256 missionId = missionCreator.createMission(
           0,
           user1,
           "",
           0,
           deadline,
           1_000_000_000_000_000_000,
           2_000_000_000_000_000_000,
           true,
           "TEST TOKEN",
           "TEST",
           "This is a test project"
        );
        uint256 projectId = missionCreator.missionIdToProjectId(missionId);

        IJBTerminal terminal = jbDirectory.primaryTerminalOf(projectId, JBConstants.NATIVE_TOKEN);
        uint256 balance = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balance, 0);

        uint256 payAmount = 1_000_000_000_000_000_000;
        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            0,
            user1,
            0,
            "",
            new bytes(0)
        );
        uint256 balanceAfter1 = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balanceAfter1, payAmount);
        uint256 tokensAfter1 = jbTokens.totalBalanceOf(user1, projectId);
        assertEq(tokensAfter1, payAmount * 2_000);

        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            payAmount,
            user1,
            0,
            "",
            new bytes(0)
        );
        uint256 balanceAfter2 = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balanceAfter2, payAmount * 2);
        uint256 tokensAfter2 = jbTokens.totalBalanceOf(user1, projectId);
        assertEq(tokensAfter2, tokensAfter1 + payAmount * 1_000);

        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            payAmount,
            user1,
            0,
            "",
            new bytes(0)
        );
        uint256 balanceAfter3 = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balanceAfter3, payAmount * 3);
        uint256 tokensAfter3 = jbTokens.totalBalanceOf(user1, projectId);
        assertEq(tokensAfter3, tokensAfter2 + payAmount * 500);

        vm.stopPrank();
    }

    function testCreateTeamProjectReachesDeadline() public {
        vm.startPrank(user1);
        uint256 deadline = block.timestamp + 2 days;
        moonDAOTeamCreator.createMoonDAOTeam{value: 0.555 ether}("", "", "","name", "bio", "image", "twitter", "communications", "website", "view", "formId", new address[](0));
        uint256 missionId = missionCreator.createMission(
           0,
           user1,
           "",
           0,
           deadline,
           1_000_000_000_000_000_000,
           2_000_000_000_000_000_000,
           true,
           "TEST TOKEN",
           "TEST",
           "This is a test project"
        );
        uint256 projectId = missionCreator.missionIdToProjectId(missionId);

        IJBTerminal terminal = jbDirectory.primaryTerminalOf(projectId, JBConstants.NATIVE_TOKEN);
        uint256 balance = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balance, 0);

        skip(2 days);
        uint256 payAmount = 1_000_000_000_000_000_000;
        vm.expectRevert();
        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            0,
            user1,
            0,
            "",
            new bytes(0)
        );
    }

    function testCreateTeamProjectBigPayment() public {
        vm.startPrank(user1);
        uint256 deadline = block.timestamp + 2 days;
        moonDAOTeamCreator.createMoonDAOTeam{value: 0.555 ether}("", "", "","name", "bio", "image", "twitter", "communications", "website", "view", "formId", new address[](0));
        uint256 missionId = missionCreator.createMission(
           0,
           user1,
           "",
           0,
           deadline,
           1_000_000_000_000_000_000,
           2_000_000_000_000_000_000,
           true,
           "TEST TOKEN",
           "TEST",
           "This is a test project"
        );
        uint256 projectId = missionCreator.missionIdToProjectId(missionId);

        IJBTerminal terminal = jbDirectory.primaryTerminalOf(projectId, JBConstants.NATIVE_TOKEN);
        uint256 balance = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balance, 0);

        uint256 payAmount = 2_000_000_000_000_000_000;
        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            0,
            user1,
            0,
            "",
            new bytes(0)
        );
        uint256 balanceAfter1 = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balanceAfter1, payAmount);
        uint256 tokensAfter1 = jbTokens.totalBalanceOf(user1, projectId);
        assertEq(tokensAfter1, 3_000 * 1e18);
    }

    function testCreateTeamProjectHugePayment() public {
        vm.startPrank(user1);
        uint256 deadline = block.timestamp + 2 days;
        moonDAOTeamCreator.createMoonDAOTeam{value: 0.555 ether}("", "", "","name", "bio", "image", "twitter", "communications", "website", "view", "formId", new address[](0));
        uint256 missionId = missionCreator.createMission(
           0,
           user1,
           "",
           0,
           deadline,
           1_000_000_000_000_000_000,
           2_000_000_000_000_000_000,
           true,
           "TEST TOKEN",
           "TEST",
           "This is a test project"
        );
        uint256 projectId = missionCreator.missionIdToProjectId(missionId);

        IJBTerminal terminal = jbDirectory.primaryTerminalOf(projectId, JBConstants.NATIVE_TOKEN);
        uint256 balance = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balance, 0);

        uint256 payAmount = 3_000_000_000_000_000_000;
        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            0,
            user1,
            0,
            "",
            new bytes(0)
        );
        uint256 balanceAfter1 = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balanceAfter1, payAmount);
        uint256 tokensAfter1 = jbTokens.totalBalanceOf(user1, projectId);
        // Due to rounding errors in calculating the weighted average, we end up with 3499999999999999999998 instead of the expected 3500000000000000000000
        assertApproxEqAbs(tokensAfter1, 3_500 * 1e18, 2);
    }

    function testCreateTeamProjectFundingCrossesGoal() public {
        vm.startPrank(user1);
        uint256 deadline = block.timestamp + 2 days;
        moonDAOTeamCreator.createMoonDAOTeam{value: 0.555 ether}("", "", "","name", "bio", "image", "twitter", "communications", "website", "view", "formId", new address[](0));
        uint256 missionId = missionCreator.createMission(
           0,
           user1,
           "",
           0,
           deadline,
           1_000_000_000_000_000_000,
           2_000_000_000_000_000_000,
           true,
           "TEST TOKEN",
           "TEST",
           "This is a test project"
        );
        uint256 projectId = missionCreator.missionIdToProjectId(missionId);

        IJBTerminal terminal = jbDirectory.primaryTerminalOf(projectId, JBConstants.NATIVE_TOKEN);
        uint256 balance = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balance, 0);

        uint256 payAmount = 1_500_000_000_000_000_000;
        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            0,
            user1,
            0,
            "",
            new bytes(0)
        );
        uint256 balanceAfter1 = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balanceAfter1, payAmount);
        uint256 tokensAfter1 = jbTokens.totalBalanceOf(user1, projectId);
        assertApproxEqAbs(tokensAfter1, 2_500 * 1e18, 1);

        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            payAmount,
            user1,
            0,
            "",
            new bytes(0)
        );
        uint256 balanceAfter2 = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balanceAfter2, payAmount * 2);
        uint256 tokensAfter2 = jbTokens.totalBalanceOf(user1, projectId);
        assertApproxEqAbs(tokensAfter2, tokensAfter1 + 1_000 * 1e18, 2);

        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            payAmount,
            user1,
            0,
            "",
            new bytes(0)
        );
        uint256 balanceAfter3 = jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
        assertEq(balanceAfter3, payAmount * 3);
        uint256 tokensAfter3 = jbTokens.totalBalanceOf(user1, projectId);
        assertEq(tokensAfter3, tokensAfter2 + payAmount * 500);

        vm.stopPrank();
    }


    function testCreateTeamProjectFundingTurnedOff() public {
        vm.startPrank(user1);
        uint256 deadline = block.timestamp + 2 days;
        moonDAOTeamCreator.createMoonDAOTeam{value: 0.555 ether}("", "", "","name", "bio", "image", "twitter", "communications", "website", "view", "formId", new address[](0));
        uint256 missionId = missionCreator.createMission(
           0,
           user1,
           "",
           0,
           deadline,
           1_000_000_000_000_000_000,
           2_000_000_000_000_000_000,
           true,
           "TEST TOKEN",
           "TEST",
           "This is a test project"
        );
        uint256 projectId = missionCreator.missionIdToProjectId(missionId);
        address payhookAddress = missionCreator.missionIdToPayHook(missionId);
        LaunchPadPayHook payhook = LaunchPadPayHook(payhookAddress);


        IJBTerminal terminal = jbDirectory.primaryTerminalOf(projectId, JBConstants.NATIVE_TOKEN);
        payhook.setFundingTurnedOff(true);

        uint256 payAmount = 1_000_000_000_000_000_000;
        vm.expectRevert();
        terminal.pay{value: payAmount}(
            projectId,
            JBConstants.NATIVE_TOKEN,
            0,
            user1,
            0,
            "",
            new bytes(0)
        );
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


// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import {MoonDAOTeam} from "../src/ERC5643.sol";
// import {GnosisSafeProxyFactory} from "../src/GnosisSafeProxyFactory.sol";
// import {JBTeamProjectCreator} from "../src/JBTeamProjectCreator.sol";
// import {JBTeamProjectsTable} from "../src/tables/JBTeamProjectsTable.sol";
// import {MoonDaoTeamTableland} from "../src/tables/MoonDaoTeamTableland.sol";
// import {TeamRowController} from "../src/tables/TeamRowController.sol";
// import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
// import {PassthroughModule} from "../src/PassthroughModule.sol";
// import {IHats} from "@hats/Interfaces/IHats.sol";
// import {Hats} from "@hats/Hats.sol";
// import {HatsModuleFactory} from "@hats-module/HatsModuleFactory.sol";
// import {deployModuleFactory} from "@hats-module/utils/DeployFunctions.sol";
// import {Whitelist} from "../src/Whitelist.sol";

// contract JBTeamProjectCreatorTest is Test {

//     address user1 = address(0x1);
//     address user2 = address(0x2);
//     address user3 = address(0x3);
//     address user4 = address(0x4);
//     address TREASURY = user4;

//     bytes32 internal constant SALT = bytes32(abi.encode(0x4a75));

//     MoonDAOTeam moonDaoTeam;
//     MoonDAOTeamCreator moonDaoTeamCreator;
//     MoonDaoTeamTableland moonDaoTeamTable;

//     JBTeamProjectCreator jbTeamProjectCreator;
//     JBTeamProjectsTable jbTeamProjectsTable;
    
//     function setUp() public {
//         vm.deal(user1, 10 ether);
//         vm.deal(user2, 10 ether);
//         vm.deal(user3, 10 ether);

//         vm.startPrank(user1);

//         Hats hatsBase = new Hats("", "");
//         IHats hats = IHats(address(hatsBase));
//         HatsModuleFactory hatsFactory = deployModuleFactory(hats, SALT, "");
//         PassthroughModule passthrough = new PassthroughModule("");
//         address gnosisSafeAddress = address(0x0165878A594ca255338adfa4d48449f69242Eb8F);
//         GnosisSafeProxyFactory proxyFactory = new GnosisSafeProxyFactory();

//         Whitelist teamWhitelist = new Whitelist();
//         Whitelist teamDiscountList = new Whitelist();

//         moonDaoTeamTable = new MoonDaoTeamTableland("MoonDaoTeamTable");
//         moonDaoTeam = new MoonDAOTeam("erc5369", "ERC5643", TREASURY, address(hatsBase), address(teamDiscountList));
//         moonDaoTeamCreator = new MoonDAOTeamCreator(address(hatsBase), address(hatsFactory), address(passthrough), address(moonDaoTeam), gnosisSafeAddress, address(proxyFactory), address(moonDaoTeamTable), address(teamWhitelist));

    
//         uint256 topHatId = hats.mintTopHat(user1, "", "");
//         uint256 moonDaoTeamAdminHatId = hats.createHat(topHatId, "", 1, TREASURY, TREASURY, true, "");

//         moonDaoTeamCreator.setOpenAccess(true);
//         moonDaoTeamTable.setMoonDaoTeam(address(moonDaoTeam));
//         moonDaoTeamCreator.setMoonDaoTeamAdminHatId(moonDaoTeamAdminHatId);
//         moonDaoTeam.setMoonDaoCreator(address(moonDaoTeamCreator));
//         hats.mintHat(moonDaoTeamAdminHatId, address(moonDaoTeamCreator));

//         jbTeamProjectCreator = new JBTeamProjectCreator(address(0), address(moonDaoTeam), address(0));
//         jbTeamProjectsTable = new JBTeamProjectsTable("TestTeamProjectsTable", address(jbTeamProjectCreator));
//         jbTeamProjectCreator.setJBTeamProjectsTable(address(jbTeamProjectsTable));

//         vm.stopPrank();
//     }

//     function testSetJBController() public {
//         // jbTeamProjectCreator.setJBController(address(0));
//         require(false,  'test');
//     }

//     function testSetMoonDAOTeam() public {
//         jbTeamProjectCreator.setMoonDaoTeam(address(moonDaoTeam));
//     }

//     function testSetJBTeamProjectsTable() public {
//         jbTeamProjectCreator.setJBTeamProjectsTable(address(jbTeamProjectsTable));
//     }

//     function testCreateTeamProject() public {
//         vm.prank(user1);
//         moonDaoTeamCreator.createMoonDAOTeam{value: 0.555 ether}("", "", "","name", "bio", "image", "twitter", "communications", "website", "view", "formId");

//         IJBPaymentTerminal[] memory terminals = new IJBPaymentTerminal[](1);
//         terminals[0] = IJBPaymentTerminal(address(0));
//         JBGroupedSplits[] memory groupedSplits = new JBGroupedSplits[](1);
//         JBFundAccessConstraints[] memory fundAccessConstraints = new JBFundAccessConstraints[](1);

//         jbTeamProjectCreator.createTeamProject(
//             0,
//             address(0),
//             JBProjectMetadata("", 0),
//             JBFundingCycleData(0, 1000000000000000000000000, 0, IJBFundingCycleBallot(address(0))),
//             JBFundingCycleMetadata(JBGlobalFundingCycleMetadata(false, false, false), 0, 10000, 0, false, false, false, false, false, false, false, false, false, false, false, false, 0x0000000000000000000000000000000000000000, 0),
//             0,
//             groupedSplits,
//             fundAccessConstraints,
//             terminals,
//             ""
//         );
        
//         vm.stopPrank();
//     }
// }


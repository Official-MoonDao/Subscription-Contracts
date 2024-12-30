// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ProjectTeam } from "./ProjectTeam.sol";
import "@hats/Interfaces/IHats.sol";
import "./GnosisSafeProxyFactory.sol";
import "./GnosisSafeProxy.sol";
import {Project} from "./tables/Project.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Whitelist} from "./Whitelist.sol";
import {PaymentSplitter} from "./PaymentSplitter.sol";
import {HatsModuleFactory} from "@hats-module/HatsModuleFactory.sol";
import {PassthroughModule} from "./PassthroughModule.sol";
import {deployModuleInstance} from "@hats-module/utils/DeployFunctions.sol";

contract ProjectTeamCreator is Ownable {

    IHats internal hats;

    ProjectTeam internal projectTeam;

    address internal gnosisSingleton;

    address internal hatsPassthrough;

    GnosisSafeProxyFactory internal gnosisSafeProxyFactory;

    HatsModuleFactory internal hatsModuleFactory;

    Project public table;

    uint256 public projectTeamAdminHatId;

    Whitelist internal whitelist;

    bool public openAccess;

    constructor(address _hats, address _hatsModuleFactory, address _hatsPassthrough, address _projectTeam, address _gnosisSingleton, address _gnosisSafeProxyFactory, address _table, address _whitelist) Ownable(msg.sender) {
        hats = IHats(_hats);
        projectTeam = ProjectTeam(_projectTeam);
        gnosisSingleton = _gnosisSingleton;
        hatsPassthrough = _hatsPassthrough;
        gnosisSafeProxyFactory = GnosisSafeProxyFactory(_gnosisSafeProxyFactory);
        hatsModuleFactory = HatsModuleFactory(_hatsModuleFactory);

        table = Project(_table);
        whitelist = Whitelist(_whitelist);
    }

    function setProjectTeamAdminHatId(uint256 _projectTeamAdminHatId) external onlyOwner() {
        projectTeamAdminHatId = _projectTeamAdminHatId;
    }

    function setOpenAccess(bool _openAccess) external onlyOwner() {
        openAccess = _openAccess;
    }

    function createProjectTeam(string memory adminHatURI, string memory managerHatURI, string memory memberHatURI, string calldata title, uint256 quarter, uint256 year, uint256 MDP, string calldata proposalIPFS, address[] memory members) external payable returns (uint256 tokenId, uint256 childHatId) {
        require(whitelist.isWhitelisted(msg.sender) || openAccess, "Only whitelisted addresses can create a Project Team");


        bytes memory safeCallData = constructSafeCallData(msg.sender);
        GnosisSafeProxy gnosisSafe = gnosisSafeProxyFactory.createProxy(gnosisSingleton, safeCallData);

        //admin hat
        uint256 teamAdminHat = hats.createHat(projectTeamAdminHatId, adminHatURI, 1, address(gnosisSafe), address(gnosisSafe), true, "");
        hats.mintHat(teamAdminHat, address(this));

        //manager hat
        uint256 teamManagerHat = hats.createHat(teamAdminHat, managerHatURI, 8, address(gnosisSafe), address(gnosisSafe), true, "");

        hats.mintHat(teamManagerHat, msg.sender);
        // loop through members and mint hats, before the safe has control
        //for (uint i = 0; i < members.length; i++) {
            //hats.mintHat(teamManagerHat, members[i]);
        //}
        hats.transferHat(teamAdminHat, address(this), address(gnosisSafe));

        //member hat
        uint256 teamMemberHat = hats.createHat(teamManagerHat, memberHatURI, 1000, address(gnosisSafe), address(gnosisSafe), true, '');

        //member hat passthrough module (allow admin hat to control member hat)
        PassthroughModule memberPassthroughModule = PassthroughModule(deployModuleInstance(hatsModuleFactory, hatsPassthrough, teamMemberHat, abi.encodePacked(teamManagerHat), "", 0));


        hats.changeHatEligibility(teamMemberHat, address(memberPassthroughModule));
        hats.changeHatToggle(teamMemberHat, address(memberPassthroughModule));

        //payment splitter
        address[] memory payees = new address[](2);
        payees[0] = address(gnosisSafe);
        payees[1] = msg.sender;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 9900;
        shares[1] = 100;
        PaymentSplitter split = new PaymentSplitter(payees, shares);

        //mint
        tokenId = projectTeam.mintTo{value: msg.value}(address(gnosisSafe), msg.sender, teamAdminHat, teamManagerHat, teamMemberHat, address(memberPassthroughModule), address(split));

        table.insertIntoTable(tokenId, title, quarter, year, MDP, proposalIPFS, "", "", "", "", 1, 0);
    }

    function constructSafeCallData(address caller) internal returns (bytes memory) {
        bytes memory part1 = hex"b63e800d0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000f48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000";

        bytes memory part2 = hex"0000000000000000000000000000000000000000000000000000000000000000";

        return abi.encodePacked(part1, caller, part2);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { MoonDAOTeam } from "./ERC5643.sol";
import "@hats/Interfaces/IHats.sol";
import "./GnosisSafeProxyFactory.sol";
import "./GnosisSafeProxy.sol";
import {MoonDaoTeamTableland} from "./tables/MoonDaoTeamTableland.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Whitelist} from "./WhiteList.sol";
import {PaymentSplitter} from "./PaymentSplitter.sol";

contract MoonDAOTeamCreator is Ownable {

    IHats internal hats;

    MoonDAOTeam internal moonDAOTeam;

    address internal gnosisSingleton;

    GnosisSafeProxyFactory internal gnosisSafeProxyFactory;

    MoonDaoTeamTableland public table;

    uint256 public MoonDaoTeamAdminHatId;

    Whitelist internal whitelist;

    bool public openAccess;

    constructor(address _hats, address _moonDAOTeam, address _gnosisSingleton, address _gnosisSafeProxyFactory, address _table, address _whitelist) Ownable(msg.sender) {
        hats = IHats(_hats);
        moonDAOTeam = MoonDAOTeam(_moonDAOTeam);
        gnosisSingleton = _gnosisSingleton;
        gnosisSafeProxyFactory = GnosisSafeProxyFactory(_gnosisSafeProxyFactory);
        table = MoonDaoTeamTableland(_table);
        whitelist = Whitelist(_whitelist);
    }

    function setMoonDaoTeamAdminHatId(uint256 _MoonDaoTeamAdminHatId) external onlyOwner() {
        MoonDaoTeamAdminHatId = _MoonDaoTeamAdminHatId;
    }

    function setOpenAccess(bool _openAccess) external onlyOwner() {
        openAccess = _openAccess;
    }

    function createMoonDAOTeam(string memory adminHatURI, string memory managerHatURI, string calldata name, string calldata bio, string calldata image, string calldata twitter, string calldata communications, string calldata website, string calldata _view, string memory formId) external payable returns (uint256 tokenId, uint256 childHatId) {

        require(whitelist.isWhitelisted(msg.sender) || openAccess, "Only whitelisted addresses can create MoonDAOTeam");
        

        bytes memory safeCallData = constructSafeCallData(msg.sender);
        GnosisSafeProxy gnosisSafe = gnosisSafeProxyFactory.createProxy(gnosisSingleton, safeCallData);
        
        //mint hat
        uint256 teamAdminHat = hats.createHat(MoonDaoTeamAdminHatId, adminHatURI, 1, address(gnosisSafe), address(gnosisSafe), true, "");
        hats.mintHat(teamAdminHat, address(this));

        uint256 teamManagerHat = hats.createHat(teamAdminHat, managerHatURI, 8, address(gnosisSafe), address(gnosisSafe), true, "");

        hats.mintHat(teamManagerHat, msg.sender);

        hats.transferHat(teamAdminHat, address(this), address(gnosisSafe));

        address[] memory payees = new address[](2);
        payees[0] = address(gnosisSafe);
        payees[1] = msg.sender;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 9900;
        shares[1] = 100;
        PaymentSplitter split = new PaymentSplitter(payees, shares);

        tokenId = moonDAOTeam.mintTo{value: msg.value}(address(gnosisSafe), teamAdminHat, teamManagerHat, address(split));

        table.insertIntoTable(tokenId, name, bio, image, twitter, communications, website, _view, formId);
    }

    function constructSafeCallData(address caller) internal returns (bytes memory) {
        bytes memory part1 = hex"b63e800d0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000017062a1de2fe6b99be3d9d37841fed19f5738040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000";

        bytes memory part2 = hex"0000000000000000000000000000000000000000000000000000000000000000";

        return abi.encodePacked(part1, caller, part2);
    }


}

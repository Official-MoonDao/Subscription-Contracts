// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC5643.sol";
import {MoonDAOTeamCreator} from "../src/MoonDAOTeamCreator.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {Hats} from "@hats/Hats.sol";

contract CreatorTest is Test {
    event SubscriptionUpdate(uint256 indexed tokenId, uint64 expiration);
    string public constant baseImageURI = "ipfs://bafkreiflezpk3kjz6zsv23pbvowtatnd5hmqfkdro33x5mh2azlhne3ah4";

    string public constant name = "Hats Protocol v1"; // increment this each deployment

    bytes32 internal constant SALT = bytes32(abi.encode(0x4a75)); // ~ H(4) A(a) T(7) S(5)

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    uint256 tokenId = 0;
    uint256 tokenId2 = 1;
    uint256 tokenId3= 2;
    string uri = "https://test.com";
    MoonDAOTeam erc5643;
    MoonDAOTeamCreator creator;

    function setUp() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        Whitelist whitelist = new Whitelist();
        whitelist.addToWhitelist(user1);

        Whitelist discountList = new Whitelist();
        Hats hats = new Hats{ salt: SALT }(name, baseImageURI);

        erc5643 = new MoonDAOTeam("erc5369", "ERC5643", 0xF69ed83F805c0C271f1A7094d5092Dc0cAFa7008, address(hats), address(discountList));
        // TODO
        creator = new MoonDAOTeamCreator(address(hats), address(erc5643), 0xfb1bffC9d739B8D520DaF37dF666da4C687191EA, 0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC, address(hats), address(whitelist));
    }

    function testMint() public {
        vm.prank(user1);
        creator.createMoonDAOTeam{value: 0.111 ether}(uri, uri, uri, "name", "bio", "image", "twitter", "communications", "website", "view", "formId");
    }



}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC5643.sol";
import {Whitelist} from "../src/Whitelist.sol";

contract ERC5643Test is Test {
    event SubscriptionUpdate(uint256 indexed tokenId, uint64 expiration);

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    uint256 tokenId = 0;
    uint256 tokenId2 = 1;
    uint256 tokenId3= 2;
    string uri = "https://test.com";
    MoonDAOTeam erc5643;

    function setUp() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        Whitelist discountList = new Whitelist();

        vm.prank(user3);
        erc5643 = new MoonDAOTeam("erc5369", "ERC5643", user3, 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137, address(discountList));
        erc5643.setMoonDaoCreator(user1);

        uint256 before = user3.balance;

        uint256 token1 = erc5643.mintTo{value: 0.1 ether}(user3, user1, 123456, 123456, 123456, address(0), address(0));
        assertEq(token1, tokenId);
        
        uint256 after_ = user3.balance;
        
        assertEq(after_ - before, 0.1 ether);
    }

    function testAdminSetURI() public {
        vm.deal(user3, 10 ether);
        // vm.prank(user3);
        // uint256 tokenId = erc5643.mintTo{value: 0.1 ether}(user2, uri);
        // vm.prank(user3);
        // erc5643.setTokenURI(tokenId, "https://reandom.com");
        // string memory tokenURI = erc5643.tokenURI(tokenId);
        // assertEq(tokenURI, "https://reandom.com");
    }


    function testRenewalInvalidTokenId() public {
        vm.prank(user1);
        vm.expectRevert(InvalidTokenId.selector);
        erc5643.renewSubscription{value: 0.1 ether}(user1, tokenId + 10, 30 days);
    }

    function testRenewalNotOwner() public {
        // vm.expectRevert(CallerNotOwnerNorApproved.selector);
        erc5643.renewSubscription{value: 0.1 ether}(user1, tokenId, 2000);
    }

    function testRenewalDurationTooShort() public {
        erc5643.setMinimumRenewalDuration(1000);
        vm.prank(user1);
        vm.expectRevert(RenewalTooShort.selector);
        erc5643.renewSubscription{value: 0.1 ether}(user1, tokenId, 999);
    }

    function testRenewalDurationTooLong() public {
        erc5643.setMaximumRenewalDuration(1000);
        vm.prank(user1);
        vm.expectRevert(RenewalTooLong.selector);
        erc5643.renewSubscription{value: 0.1 ether}(user1, tokenId, 1001);
    }

    function testRenewalInsufficientPayment() public {
        vm.prank(user1);
        vm.expectRevert(InsufficientPayment.selector);
        erc5643.renewSubscription{value: 0.008 ether}(user1, tokenId, 30 days);
    }

    function testRenewalExistingSubscription() public {
        uint256 currTime = block.timestamp;
        vm.warp(1000);
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId, 31536000 + 30 days + 1 );
        erc5643.renewSubscription{value: 0.1 ether}(user1, tokenId, 30 days);
        assertEq(user1.balance, 9.9 ether);
    }

    function testRenewalNewSubscription() public {
        vm.warp(1000);
        vm.prank(user2);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId2, 365 days + 1000);
        erc5643.mintTo{value: 0.1 ether}(user2, user2, 123456, 123456, 123456, address(0), address(0));

        // This renewal will succeed because the subscription is renewable
        vm.prank(user2);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId2, 365 days + 30 days + 1000);
        erc5643.renewSubscription{value: 0.1 ether}(user2, tokenId2, 30 days);
    }

    function testCancelValid() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId, 0);
        erc5643.cancelSubscription(tokenId);
    }

    function testCancelNotOwner() public {
        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        erc5643.cancelSubscription(tokenId);
    }

    function testExpiresAt() public {
        uint256 currTime = block.timestamp;
        vm.warp(1000);

        assertEq(erc5643.expiresAt(tokenId), 31536001 + currTime - 1);
        vm.startPrank(user1);
        erc5643.renewSubscription{value: 0.1 ether}(user1, tokenId, 2000);
        assertEq(erc5643.expiresAt(tokenId), 31536001 + 2000 + currTime - 1);

        erc5643.cancelSubscription(tokenId);
        assertEq(erc5643.expiresAt(tokenId), 0);
    }

    function testExpiresAtInvalidToken() public {
        vm.expectRevert(InvalidTokenId.selector);
        erc5643.expiresAt(tokenId2 + 10);
    }

    function testIsRenewableInvalidToken() public {
        vm.expectRevert(InvalidTokenId.selector);
        erc5643.isRenewable(tokenId2 + 10);
    }

    function testExtendSubscriptionInvalidToken() public {
        vm.expectRevert(InvalidTokenId.selector);
        erc5643.renewSubscription{value: 0.1 ether}(user1, tokenId + 100, 30 days);
    }

    function testRenewalDiscount() public {
        vm.warp(1000);
        vm.startPrank(user2);

        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId2, 365 days + 1000);
        uint256 id = erc5643.mintTo{value: 1 ether}(user2, user2, 123456, 123456, 123456, address(0), address(0));
        assertEq(erc5643.expiresAt(tokenId2), 365 days + 1000);

        vm.deal(user2, 1 ether);
        // without discount it's 1.2 eth
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId2, 365 days + 365 days + 1000);
        erc5643.renewSubscription{value: 1 ether}(user2, tokenId2, 365 days);
        
    }

    function testTransfer() public {
        vm.prank(user1);
        vm.expectRevert("You may not transfer your token!");
        erc5643.transferFrom(user1, user2, 0);
    }

    function testURI() public {
        string memory tokenURI = erc5643.tokenURI(tokenId);
        assertEq(tokenURI, uri);
    }

    function testContractOnwerUpdateURI() public {
        // erc5643.setTokenURIOwner(tokenId, "https://reandom.com");
        string memory tokenURI = erc5643.tokenURI(tokenId);
        assertEq(tokenURI, "https://reandom.com");
    }

    function testTokenOnwerUpdateURI() public {
        vm.prank(user1);
        // erc5643.setTokenURIOwner(tokenId, "https://reandom.com");
        string memory tokenURI = erc5643.tokenURI(tokenId);
        assertEq(tokenURI, "https://reandom.com");
    }

    function testNotTokenOwnerUpdateURI() public {
        vm.prank(user2);
        vm.expectRevert("Only token owner or contract owner can set URI");
        // erc5643.setTokenURIOwner(tokenId, "https://reandom.com");
    }
}

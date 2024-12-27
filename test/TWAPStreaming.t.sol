// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/LMSRWithTWAP.sol";

interface WETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function decimals() external view returns (uint);
}
interface LMSR {
    function collateralToken() external view returns (address);
    function calcNetCost(int[] memory outcomeTokenAmounts) external view returns (int);
    function atomicOutcomeSlotCount() external view returns (uint);
    function trade(int[] memory outcomeTokenAmounts, int cost) external;
}

contract TestLMSRWithTwap is Test {
    LMSRWithTWAP lmsrWithTWAP;
    LMSR lmsr;
    WETH weth;
    address user1;

    function setUp() public {
        lmsrWithTWAP = new LMSRWithTWAP(0xD972a38702e55c160DfedF66f23907061D971066);
        lmsr = LMSR(lmsrWithTWAP.marketMakerAddress());
        weth = WETH(lmsr.collateralToken());
        user1 = address(0x0000000000000000000000000000000000000001);
        vm.deal(user1, 10 ether);
    }

    function testLMSRWithTwap() public {
        vm.startPrank(user1);
        console.log("LMSRWithTWAP address: %s", address(lmsrWithTWAP));
        console.log("LMSR address: %s", address(lmsr));
        console.log("startTime: %s", lmsrWithTWAP.startTime());
        console.log("block.timestamp: %s", block.timestamp);
        console.log("atomicOutcomeSlotCount: %s", lmsr.atomicOutcomeSlotCount());
        weth.deposit{value: 1 ether}();
        weth.approve(address(lmsr), 1 ether);
        weth.approve(address(lmsrWithTWAP), 1 ether);
        console.log("weth.balanceOf(address(this)): %s", weth.balanceOf(address(this)));
        int[] memory outcomeTokenAmounts = new int[](8);
        outcomeTokenAmounts[0] = 1 * 10 ** 14;
        int cost = lmsr.calcNetCost(outcomeTokenAmounts);
        console.log("cost:");
        //console.log("cost: %s", lmsr.calcNetCost(outcomeTokenAmounts));
        //console.log("outcomeTokenAmounts[1]: %s", outcomeTokenAmounts[1]);
        //lmsr.trade(outcomeTokenAmounts, cost);
        lmsrWithTWAP.trade(outcomeTokenAmounts, cost);
        //lmsrWithTWAP.getTWAP();
        //lmsrWithTWAP.updateCumulativeTWAP();
        vm.stopPrank();
    }
}


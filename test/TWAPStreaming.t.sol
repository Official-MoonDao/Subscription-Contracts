// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
//import "../src/LMSRWithTWAP.sol";

interface WETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function decimals() external view returns (uint);
}
interface LMSRWithTWAP {
    function collateralToken() external view returns (address);
    function calcNetCost(int[] memory outcomeTokenAmounts) external view returns (int);
    function atomicOutcomeSlotCount() external view returns (uint);
    function trade(int[] memory outcomeTokenAmounts, int cost) external;
    function getTWAP() external view returns (uint);
    function updateCumulativeTWAP() external;
    function startTime() external view returns (uint);
}

contract TestLMSRWithTwap is Test {
    LMSRWithTWAP lmsrWithTWAP;
    //LMSR lmsr;
    WETH weth;
    address user1;

    function setUp() public {
        lmsrWithTWAP = LMSRWithTWAP(0xa0B1b14515C26acb193cb45Be5508A8A46109a27);
        weth = WETH(lmsrWithTWAP.collateralToken());
        user1 = address(0x0000000000000000000000000000000000000001);
        vm.deal(user1, 10 ether);
    }

    function testLMSRWithTwap() public {
        vm.startPrank(user1);
        console.log("LMSRWithTWAP address: %s", address(lmsrWithTWAP));
        console.log("startTime: %s", lmsrWithTWAP.startTime());
        console.log("block.timestamp: %s", block.timestamp);
        console.log("atomicOutcomeSlotCount: %s", lmsrWithTWAP.atomicOutcomeSlotCount());
        console.log("collateralToken: %s", lmsrWithTWAP.collateralToken());
        weth.deposit{value: 1 ether}();
        weth.approve(address(lmsrWithTWAP), 1 ether);
        console.log("weth.balanceOf(address(user1)): %s", weth.balanceOf(user1));
        int[] memory outcomeTokenAmounts = new int[](3);
        outcomeTokenAmounts[0] = 1 * 10 ** 15;
        int cost = lmsrWithTWAP.calcNetCost(outcomeTokenAmounts);
        console.log("cost:");
        //console.log("cost: %s", lmsr.calcNetCost(outcomeTokenAmounts));
        //console.log("outcomeTokenAmounts[1]: %s", outcomeTokenAmounts[1]);
        //lmsr.trade(outcomeTokenAmounts, cost);
        lmsrWithTWAP.trade(outcomeTokenAmounts, cost);
        lmsrWithTWAP.getTWAP();
        //lmsrWithTWAP.updateCumulativeTWAP();
        vm.stopPrank();
    }
}


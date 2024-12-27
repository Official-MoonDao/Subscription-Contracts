pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/VotingEscrowDepositor.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);


        VotingEscrowDepositor sender = VotingEscrowDepositor(address(0xBE19a62384014F103686dfE6D9d50B1D3E81B2d0));
        address[] memory addresses = new address[](1);
        addresses[0] = address(0x47ee48E1766BaC43dEc10215Dd636102126eA8fa);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1000000000000000000;
        sender.increaseWithdrawAmounts(
            addresses,
            amounts
        );

        vm.stopBroadcast();
    }
}

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CrossChainMinter.sol";

contract MyScript is Script {



    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        uint32 eid;

        address arbSepAddress = 0xfF113d31149F63732B8943a9Ea12b738cB343202;
        address sepAddress = 0x51a5cA8966cA71ac0A0D58DbeF2ec6a932e1490E;
        if(block.chainid == 1) { //mainnet
            eid = 30101;
        } else if (block.chainid == 8453) { //base
            eid = 8453;
        } else if (block.chainid == 84532) { //base-sep
            eid = 40245;
        } else if (block.chainid == 421614) { //arb-sep
            eid = 40231;
            // testing arb-sep -> sep
            uint32 sepEid = 40161;
            CrossChainMinter minter = CrossChainMinter(arbSepAddress);
            minter.setPeer(sepEid , addressToBytes32(sepAddress));
        } else if (block.chainid == 11155111) { //sep
            eid = 40161;
            // sep -> arb-sep
            uint32 arbSepEid = 40231;
            CrossChainMinter minter = CrossChainMinter(sepAddress);
            minter.setPeer(arbSepEid , addressToBytes32(arbSepAddress));
        }



        vm.stopBroadcast();
    }
}

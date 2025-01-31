pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CrossChainMinter.sol";

contract MyScript is Script {




    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address lzEndpoint;
        // Citizen addresses
        //arbitrum: '0x6E464F19e0fEF3DB0f3eF9FD3DA91A297DbFE002',
        //sepolia: '0x31bD6111eDde8D8D6E12C8c868C48FF3623CF098',
        //'arbitrum-sepolia': '0x853d6B4BA61115810330c7837FDD24D61CBab855',
        address citizenAddress = 0x31bD6111eDde8D8D6E12C8c868C48FF3623CF098;
        uint32 eid;
        if(block.chainid == 1) { //mainnet
            lzEndpoint = 0x1a44076050125825900e736c501f859c50fE728c;
            eid = 30101;
        } else if (block.chainid == 8453) { //base
            lzEndpoint = 0x1a44076050125825900e736c501f859c50fE728c;
            eid = 8453;
        } else if (block.chainid == 84532) { //base-sep
            lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
            eid = 40245;
        } else if (block.chainid == 421614) { //arb-sep
            lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
            eid = 40231;
        } else if (block.chainid == 11155111) { //sep
            lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
            eid = 40161;
        }
        CrossChainMinter minter = new CrossChainMinter(lzEndpoint, citizenAddress);
        vm.stopBroadcast();
    }
}


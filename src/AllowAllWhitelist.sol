// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract AllowAllWhitelist {
    function check(address _wallet) external view returns (bool) {
        return true;
    }

}


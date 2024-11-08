// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("Mock Token", "MTK") {
        _mint(msg.sender, initialSupply);
    }

    // Helper function to allow the sender to give allowance
    function approveFor(address owner, address spender, uint256 amount) public {
        _approve(owner, spender, amount);
    }
}


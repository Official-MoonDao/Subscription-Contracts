// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for ERC20 tokens
interface IERC20Interface {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BulkTokenSender {
    // Function to send an ERC20 token to multiple recipients
    function send(
        address token,               // Address of the ERC20 token contract
        address[] memory recipients,  // Array of recipient addresses
        uint256[] memory amounts      // Array of amounts to send to each recipient
    ) public {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");

        IERC20Interface tokenContract = IERC20Interface(token);  // Initialize the token contract interface

        for (uint256 i = 0; i < recipients.length; i++) {
            require(tokenContract.transferFrom(msg.sender, recipients[i], amounts[i]), "Token transfer failed");
        }
    }
}

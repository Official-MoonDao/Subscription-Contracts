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


    function uploadAllocationResult(address[] memory recipients, uint256[] memory percents) public {
        assert(recipients.length == percents.length);
    
        // get current timestamp
        uint256 currentTimestamp = block.timestamp;
        assert(currentTimestamp > lastAllocationUpdateTimestamp);

        // find the difference between the current timestamp and the last allocation update timestamp
        uint256 timeSinceLastUpdate = currentTimestamp - lastAllocationUpdateTimestamp;
        lastAllocationUpdateTimestamp = currentTimestamp;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (i >= currentRecipients.length) {
                //append the new recipient
                currentRecipients.push(recipients[i]);
                currentAmounts.push(0);
                currentSplitPercent.push(percents[i]);
            } else {
                assert(currentRecipients[i] == recipients[i]);
                currentAmounts[i] += timeSinceLastUpdate * totalPrizeAllocationPerSecond * currentSplitPercent[i];
            }

            
            // update the current split percent
            currentSplitPercent[i] = percents[i];
        }
    }


    function claimAllocation(address token) public {
        // get current timestamp
        uint256 currentTimestamp = block.timestamp;
        // find the difference between the current timestamp and the last allocation update timestamp
        uint256 timeSinceLastUpdate = currentTimestamp - lastAllocationUpdateTimestamp;
                lastAllocationUpdateTimestamp = currentTimestamp;

        for (uint256 i = 0; i < currentRecipients.length; i++) {
            currentAmounts[i] += timeSinceLastUpdate * totalPrizeAllocationPerSecond * currentSplitPercent[i];

            if (currentRecipients[i] == msg.sender) {
                uint256 amountToWithdraw = currentAmounts[i];
                currentAmounts[i] = 0;
                IERC20Interface tokenContract = IERC20Interface(token);  // Initialize the token contract interface
                require(tokenContract.transfer(msg.sender, amountToWithdraw), "Token transfer failed");
            }
        }


    }



    function addPrize(address token, uint256 amount) public {
        IERC20Interface tokenContract = IERC20Interface(token);  // Initialize the token contract interface
        // transfer the amount from the user to the contract
        require(tokenContract.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // calculate the total prize allocation per second
        totalPrize = totalPrize + amount;

        // Convert to fixed point math to handle decimals
        totalPrizeAllocationPerSecond = (totalPrize * 10 / 100) / 30 days;
    }


    // Total amount of $PRIZE
    uint256 public totalPrize;

    // Total amount of $PRIZE allocated per second
    uint256 public totalPrizeAllocationPerSecond;

    // Last timestamp when allocations were updated
    uint256 public lastAllocationUpdateTimestamp;


    // Current recipients of the allocation
    address[] public currentRecipients;

    // Current split percent of the allocation
    uint256[] public currentSplitPercent;

    // Current amounts of the allocation
    uint256[] public currentAmounts;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for ERC20 tokens
interface IERC20Interface {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DePrize {

    function uploadSplit(address[] memory recipients, uint256[] memory percents) public {
        assert(recipients.length == percents.length);
        assert(winner == address(0));
    
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


    function claimRewards(address token) public {
        // get current timestamp
        uint256 currentTimestamp = block.timestamp;
        // find the difference between the current timestamp and the last allocation update timestamp
        uint256 timeSinceLastUpdate = currentTimestamp - lastAllocationUpdateTimestamp;
        lastAllocationUpdateTimestamp = currentTimestamp;

        for (uint256 i = 0; i < currentRecipients.length; i++) {

            if (winner != address(0)) {
                uint256 increment = timeSinceLastUpdate * totalPrizeAllocationPerSecond * currentSplitPercent[i];
                currentAmounts[i] += increment;
                totalPrize -= increment;
            }

            if (currentRecipients[i] == msg.sender) {
                uint256 amountToWithdraw = currentAmounts[i];
                currentAmounts[i] = 0;
                IERC20Interface tokenContract = IERC20Interface(token);  // Initialize the token contract interface
                require(tokenContract.transfer(msg.sender, amountToWithdraw), "Token transfer failed");
            }
        }
    }


    function addPrize(address token, uint256 amount) public {
        // Can only add prize before the winner is set
        assert(winner == address(0));

        IERC20Interface tokenContract = IERC20Interface(token);  // Initialize the token contract interface
        // transfer the amount from the user to the contract
        require(tokenContract.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // calculate the total prize allocation per second
        totalPrize = totalPrize + amount;

        // Convert to fixed point math to handle decimals
        totalPrizeAllocationPerSecond = (totalPrize * 10 / 100) / 30 days;
    }


    function setWinner(address winnerAddress, address[] memory voterRewardsRecipients, uint256[] memory voterRewardsPercents) public {
        assert(winner == address(0));
        
        // get current timestamp
        uint256 currentTimestamp = block.timestamp;
        // find the difference between the current timestamp and the last allocation update timestamp
        uint256 timeSinceLastUpdate = currentTimestamp - lastAllocationUpdateTimestamp;
        lastAllocationUpdateTimestamp = currentTimestamp;

        uint256 winnerID = 0;
        for (uint256 i = 0; i < currentRecipients.length; i++) {
            uint256 increment = timeSinceLastUpdate * totalPrizeAllocationPerSecond * currentSplitPercent[i];
            currentAmounts[i] += increment;
            totalPrize -= increment;

            if (currentRecipients[i] == winnerAddress) {
                winnerID = i;
                winner = winnerAddress;
            }
        }

        // Calculate the winner's reward
        uint256 winnerReward = totalPrize * 75 / 100;
        currentAmounts[winnerID] += winnerReward;
        totalPrize -= winnerReward;

        // Calculate the voter rewards
        uint256 voterReward = totalPrize * 25 / 100;
        for (uint256 i = 0; i < voterRewardsRecipients.length; i++) {
            uint256 voterRewardAmount = voterReward * voterRewardsPercents[i] / 100;
            currentRecipients.push(voterRewardsRecipients[i]);
            currentAmounts.push(voterRewardAmount);
        }
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

    // Winner of the prize
    address public winner = address(0);
}

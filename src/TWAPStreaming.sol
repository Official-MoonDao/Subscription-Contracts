// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILMSRWithTWAP {
    function getTWAP() external view returns (uint256[] memory);
    function marketMaker() external view returns (address);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}
interface IERC721{
    function ownerOf(uint256 tokenId) external view returns (address);
}
interface ICompetitor{
    function deprizeIdToId(uint256) external view returns (uint256);
}
contract TWAPStreaming {
    ILMSRWithTWAP public twapContract;
    IERC20 public token;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalFunds;

    address[] public outcomeRecipients; // one address per outcome
    address public competitorTable;
    IERC721 public teamNFT;

    // Track how much each outcome has already claimed
    uint256[] public claimedAmounts;

    constructor(
        address _twapContract,
        address _competitorTable,
        address _teamNFT,
        address _token,
        address[] memory _outcomeRecipients,
        uint256 _totalFunds,
        uint256 _startTime,
        uint256 _endTime
    ) {
        require(_startTime < _endTime, "Invalid time window");
        require(_outcomeRecipients.length > 0, "No outcomes");
        require(_twapContract != address(0) && _token != address(0), "Zero addresses");

        twapContract = ILMSRWithTWAP(_twapContract);
        teamNFT = IERC721(_teamNFT);
        token = IERC20(_token);
        outcomeRecipients = _outcomeRecipients;
        totalFunds = _totalFunds;
        startTime = _startTime;
        endTime = _endTime;

        claimedAmounts = new uint256[](_outcomeRecipients.length);
    }

    /**
     * @notice Allows recipients to withdraw their accrued portion of funds.
     * @param outcomeIndex The index of the outcome the caller represents.
     *        In a production scenario, you might restrict this so only the
     *        outcome recipient address can withdraw their portion or you
     *        have a more open approach.
     */
    function withdraw(uint256 outcomeIndex) external {
        require(outcomeIndex < outcomeRecipients.length, "Invalid outcome index");
        require(block.timestamp >= startTime, "Streaming not started");

        // Calculate how much is currently claimable for this outcome
        uint256 claimable = calcClaimableAmount(outcomeIndex);
        uint256 alreadyClaimed = claimedAmounts[outcomeIndex];

        require(claimable > alreadyClaimed, "Nothing to claim");
        uint256 amountToClaim = claimable - alreadyClaimed;

        // Update state
        claimedAmounts[outcomeIndex] = claimable;

        // Transfer tokens to the recipient
        address recipient = outcomeRecipients[outcomeIndex];
        require(token.transfer(recipient, amountToClaim), "Token transfer failed");
    }

    /**
     * @notice Calculate how much is currently claimable by a given outcome,
     *         taking into account the linear release schedule and the TWAP.
     */
    function calcClaimableAmount(uint256 outcomeIndex) public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        }

        // Determine how much of the totalFunds are unlocked
        uint256 elapsed = block.timestamp > endTime ? (endTime - startTime) : (block.timestamp - startTime);
        uint256 unlockedFunds = (totalFunds * elapsed) / (endTime - startTime);

        // Get current TWAP probabilities
        uint256[] memory twap = twapContract.getTWAP();
        require(outcomeIndex < twap.length, "Mismatch in outcome indexing");

        // twap[i] are the probabilities scaled by 1e18 (assumption)
        // Sum of all twap[i] should be approximately 1e18.
        // The fraction allocated to this outcome is twap[outcomeIndex] / 1e18
        uint256 outcomeProbability = twap[outcomeIndex];

        // Amount allocated to this outcome so far
        // (unlockedFunds * outcomeProbability) / 1e18
        uint256 outcomeAmount = (unlockedFunds * outcomeProbability) / 1e18;
        return outcomeAmount;
    }

    /**
     * @notice View function to see how much total remains for each outcome
     *         (total at end minus already claimed).
     */
    function totalRemainingFor(uint256 outcomeIndex) external view returns (uint256) {
        uint256 claimable = calcClaimableAmount(outcomeIndex);
        return claimable > claimedAmounts[outcomeIndex] ? (claimable - claimedAmounts[outcomeIndex]) : 0;
    }
}


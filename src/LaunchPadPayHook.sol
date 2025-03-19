// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {JBPayHookSpecification} from "@nana-core/structs/JBPayHookSpecification.sol";
import {JBBeforePayRecordedContext} from "@nana-core/structs/JBBeforePayRecordedContext.sol";
import {JBBeforeCashOutRecordedContext} from "@nana-core/structs/JBBeforeCashOutRecordedContext.sol";
import {JBCashOutHookSpecification} from "@nana-core/structs/JBCashOutHookSpecification.sol";
import {IJBTerminalStore} from "@nana-core/interfaces/IJBTerminalStore.sol";
import {IJBRulesetDataHook} from "@nana-core/interfaces/IJBRulesetDataHook.sol";
import { JBConstants } from "@nana-core/libraries/JBConstants.sol";


// LaunchPadPayHook implements the common logic:
//   • Storing minFundingRequired, fundingGoal and deadline.
//   • Holding references to the IJBTerminalStore contract.
//   • A helper function (_totalFunding) to read total funding.
//   • An Ownable toggle (setFundingTurnedOff) for the fundingTurnedOff flag.
//   • The beforePayRecordedWith function manipulates the weight to change number
//     of tokens received per ETH based on the funding status.
contract LaunchPadPayHook is IJBRulesetDataHook, Ownable {

    uint256 public immutable minFundingRequired;
    uint256 public immutable fundingGoal;
    uint256 public immutable deadline;

    // fundingTurnedOff can be toggled by the owner.
    bool public fundingTurnedOff;

    IJBTerminalStore public jbTerminalStore;

    constructor(
        uint256 _minFundingRequired,
        uint256 _fundingGoal,
        uint256 _deadline,
        address _jbTerminalStoreAddress,
        address owner
    ) Ownable(owner) {
        minFundingRequired = _minFundingRequired;
        fundingGoal = _fundingGoal;
        deadline = _deadline;
        jbTerminalStore = IJBTerminalStore(_jbTerminalStoreAddress);
    }

    function setFundingTurnedOff(bool _fundingTurnedOff) external onlyOwner {
        fundingTurnedOff = _fundingTurnedOff;
    }

    function _totalFunding(address terminal, uint256 projectId) internal view returns (uint256) {
        return jbTerminalStore.balanceOf(terminal, projectId, JBConstants.NATIVE_TOKEN);
    }

    function beforePayRecordedWith(JBBeforePayRecordedContext calldata context) external view override returns (uint256 weight, JBPayHookSpecification[] memory hookSpecifications) {
        if (fundingTurnedOff) {
            revert("Project funding has been turned off.");
        }

        // Get current funding and the incoming payment amount.
        uint256 currentFunding = _totalFunding(context.terminal, context.projectId);
        require(context.amount.token == JBConstants.NATIVE_TOKEN);
        uint256 paymentAmount = context.amount.value;

        // Define our rates:
        // Rate values include the 1e18 multiplier, and are doubled (due to 50% project tokens split as noted).
        uint256 rateTier1 = 4_000_000_000_000_000_000_000; // 2,000 tokens per ETH for funding below minFundingRequired
        uint256 rateTier2 = 2_000_000_000_000_000_000_000; // 1,000 tokens per ETH for funding between minFundingRequired and fundingGoal
        uint256 rateTier3 = 1_000_000_000_000_000_000_000; // 500 tokens per ETH for funding above fundingGoal

        weight = 0;
        uint256 remainingPayment = paymentAmount;
        uint256 tempFunding = currentFunding;

        // In the case where a payment will bring a project over minFundingRequired or fundingGoal
        // we need to calculate the weighted average of the rates.

        // Tier 1: Payments that bring total funding up to minFundingRequired.
        if (tempFunding < minFundingRequired) {
            if (block.timestamp >= deadline) {
                revert("Project funding deadline has passed and minimum funding requirement has not been met.");
            }
            uint256 availableTier1 = minFundingRequired - tempFunding;
            // Payment applied in Tier 1 is the lesser of the available capacity and the full payment.
            uint256 paymentTier1 = remainingPayment < availableTier1 ? remainingPayment : availableTier1;
            weight += (paymentTier1 * rateTier1) / paymentAmount;
            remainingPayment -= paymentTier1;
            tempFunding += paymentTier1;
        }

        // Tier 2: Payments that fill funding from minFundingRequired up to fundingGoal.
        if (remainingPayment > 0 && tempFunding < fundingGoal) {
            uint256 availableTier2 = fundingGoal - tempFunding;
            uint256 paymentTier2 = remainingPayment < availableTier2 ? remainingPayment : availableTier2;
            weight += (paymentTier2 * rateTier2) / paymentAmount;
            remainingPayment -= paymentTier2;
            tempFunding += paymentTier2;
        }

        // Tier 3: Payments beyond the fundingGoal.
        if (remainingPayment > 0) {
            weight += (remainingPayment * rateTier3) / paymentAmount;
            remainingPayment = 0;
        }
    }
    function beforeCashOutRecordedWith(JBBeforeCashOutRecordedContext calldata context) external view override
        returns (
        uint256 cashOutTaxRate,
        uint256 cashOutCount,
        uint256 totalSupply,
        JBCashOutHookSpecification[] memory hookSpecifications
    ){
    }

    function hasMintPermissionFor(uint256 projectId, address addr) external view override returns (bool flag){
        return false;
    }

    /// @notice ERC165 support.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IJBRulesetDataHook).interfaceId;
    }
}

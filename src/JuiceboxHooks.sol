// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {JBApprovalStatus} from "@nana-core/enums/JBApprovalStatus.sol";
import {IJBRulesetApprovalHook} from "@nana-core/interfaces/IJBRulesetApprovalHook.sol";
import {IJBDirectory} from "@nana-core/interfaces/IJBDirectory.sol";
import {IJBTerminalStore} from "@nana-core/interfaces/IJBTerminalStore.sol";
import {IJBTerminal} from "@nana-core/interfaces/IJBTerminal.sol";
import { JBConstants } from "@nana-core/libraries/JBConstants.sol";


// -- BASE CONTRACT --
//
// JBApprovalHookBase implements the common logic:
//   • Storing minFundingRequired, fundingGoal, deadline, and a duration (which is returned via DURATION())
//   • Holding references to the JBDirectory and IJBTerminalStore contracts.
//   • A helper function (_totalFunding) to read total funding.
//   • An Ownable toggle (setFundingTurnedOff) for the fundingTurnedOff flag.
abstract contract JBApprovalHookBase is IJBRulesetApprovalHook, Ownable {
    uint256 public immutable minFundingRequired;
    uint256 public immutable fundingGoal;
    uint256 public immutable deadline;
    uint256 public immutable duration; // Duration of this hook's cycle.

    // fundingTurnedOff can be toggled by the owner.
    bool public fundingTurnedOff;

    IJBDirectory public jbDirectory;
    IJBTerminalStore public jbTerminalStore;

    constructor(
        uint256 _minFundingRequired,
        uint256 _fundingGoal,
        uint256 _deadline,
        uint256 _duration,
        address _jbDirectoryAddress,
        address _jbTerminalStoreAddress
    ) Ownable(msg.sender) {
        minFundingRequired = _minFundingRequired;
        fundingGoal = _fundingGoal;
        deadline = _deadline;
        duration = _duration;
        jbDirectory = IJBDirectory(_jbDirectoryAddress);
        jbTerminalStore = IJBTerminalStore(_jbTerminalStoreAddress);
    }

    /// @dev Returns the total funding for a project by:
    ///  1. Getting the primary terminal from the JBDirectory.
    ///  2. Calling balanceOf on the terminal store.
    function _totalFunding(uint256 projectId) internal view returns (uint256) {
        IJBTerminal terminal = jbDirectory.primaryTerminalOf(projectId, JBConstants.NATIVE_TOKEN);
        return jbTerminalStore.balanceOf(address(terminal), projectId, JBConstants.NATIVE_TOKEN);
    }

    /// @notice Allows the owner to turn funding on/off.
    function setFundingTurnedOff(bool _fundingTurnedOff) external onlyOwner {
        fundingTurnedOff = _fundingTurnedOff;
    }

    /// @notice Returns the cycle duration.
    function DURATION() external view override returns (uint256) {
        return duration;
    }

    /// @notice ERC165 support.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IJBRulesetApprovalHook).interfaceId;
    }
}


// -- CONCRETE HOOK CONTRACTS --
//
// Cycle 1: Early Party Approval Hook
//
// Logic:
//   • If totalFunding >= minFundingRequired → Approved
//   • Else if fundingTurnedOff is true OR block.timestamp > deadline → Approved
//   • Else → Failed
//
contract Cycle1ApprovalHook is JBApprovalHookBase {
    constructor(
        uint256 _minFundingRequired,
        uint256 _fundingGoal,
        uint256 _deadline,
        uint256 _duration,
        address _jbDirectoryAddress,
        address _jbTerminalStoreAddress
    )
        JBApprovalHookBase(
            _minFundingRequired,
            _fundingGoal,
            _deadline,
            _duration,
            _jbDirectoryAddress,
            _jbTerminalStoreAddress
        )
    {}

    function approvalStatusOf(
        uint256 projectId,
        uint256 /*rulesetId*/,
        uint256 /*start*/
    ) external view override returns (JBApprovalStatus) {
        uint256 totalFunding = _totalFunding(projectId);

        if (totalFunding >= minFundingRequired) {
            return JBApprovalStatus.Approved;
        }
        if (fundingTurnedOff || block.timestamp > deadline) {
            return JBApprovalStatus.Approved;
        }
        return JBApprovalStatus.Failed;
    }
}


//
// Refund Trap Approval Hook
//
// Logic:
//   • If totalFunding < minFundingRequired → Failed
//   • Else → Approved
//
contract RefundTrapApprovalHook is JBApprovalHookBase {
    constructor(
        uint256 _minFundingRequired,
        uint256 _fundingGoal,
        uint256 _deadline,
        uint256 _duration,
        address _jbDirectoryAddress,
        address _jbTerminalStoreAddress
    )
        JBApprovalHookBase(
            _minFundingRequired,
            _fundingGoal,
            _deadline,
            _duration,
            _jbDirectoryAddress,
            _jbTerminalStoreAddress
        )
    {}

    function approvalStatusOf(
        uint256 projectId,
        uint256 /*rulesetId*/,
        uint256 /*start*/
    ) external view override returns (JBApprovalStatus) {
        uint256 totalFunding = _totalFunding(projectId);

        if (totalFunding < minFundingRequired) {
            return JBApprovalStatus.Failed;
        }
        return JBApprovalStatus.Approved;
    }
}


//
// Cycle 2: Active Funding Approval Hook
//
// Logic:
//   • If totalFunding > fundingGoal → Approved
//   • Else → Failed
//
contract Cycle2ApprovalHook is JBApprovalHookBase {
    constructor(
        uint256 _minFundingRequired,
        uint256 _fundingGoal,
        uint256 _deadline,
        uint256 _duration,
        address _jbDirectoryAddress,
        address _jbTerminalStoreAddress
    )
        JBApprovalHookBase(
            _minFundingRequired,
            _fundingGoal,
            _deadline,
            _duration,
            _jbDirectoryAddress,
            _jbTerminalStoreAddress
        )
    {}

    function approvalStatusOf(
        uint256 projectId,
        uint256 /*rulesetId*/,
        uint256 /*start*/
    ) external view override returns (JBApprovalStatus) {
        uint256 totalFunding = _totalFunding(projectId);

        if (totalFunding > fundingGoal) {
            return JBApprovalStatus.Approved;
        }
        return JBApprovalStatus.Failed;
    }
}


//
// Cycle 3: Open Contributions Approval Hook
//
// Logic: (Same as Cycle 2)
//   • If totalFunding > fundingGoal → Approved
//   • Else → Failed
//
contract Cycle3ApprovalHook is JBApprovalHookBase {
    constructor(
        uint256 _minFundingRequired,
        uint256 _fundingGoal,
        uint256 _deadline,
        uint256 _duration,
        address _jbDirectoryAddress,
        address _jbTerminalStoreAddress
    )
        JBApprovalHookBase(
            _minFundingRequired,
            _fundingGoal,
            _deadline,
            _duration,
            _jbDirectoryAddress,
            _jbTerminalStoreAddress
        )
    {}

    function approvalStatusOf(
        uint256 projectId,
        uint256 /*rulesetId*/,
        uint256 /*start*/
    ) external view override returns (JBApprovalStatus) {
        uint256 totalFunding = _totalFunding(projectId);

        if (totalFunding > fundingGoal) {
            return JBApprovalStatus.Approved;
        }
        return JBApprovalStatus.Failed;
    }
}

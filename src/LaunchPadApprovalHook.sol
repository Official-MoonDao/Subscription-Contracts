// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@nana-core/interfaces/IJBRulesetApprovalHook.sol";
import "@nana-core/interfaces/IJBTerminalStore.sol";
import "@nana-core/libraries/JBConstants.sol";

contract LaunchPadApprovalHook is IJBRulesetApprovalHook {
    uint256 public immutable fundingGoal;
    uint256 public immutable deadline; // how long after start we wait
    IJBTerminalStore public immutable jbTerminalStore;
    address public immutable terminal;

    /// @param _jbTerminalStoreAddress The Juicebox terminal store
    /// @param _terminal The specific terminal to pull balances from
    /// @param _fundingGoal Minimum amount of native tokens to allow approval
    /// @param _deadline Time window (in seconds) after `start` before auto-approval
    constructor(
        uint256 _fundingGoal,
        uint256 _deadline,
        address _jbTerminalStoreAddress,
        address _terminal
    ) {
        fundingGoal = _fundingGoal;
        deadline = _deadline;
        jbTerminalStore = IJBTerminalStore(_jbTerminalStoreAddress);
        terminal = _terminal;
    }

    /// @notice How long after the ruleset’s `start` we’ll wait before approving
    function DURATION() external view override returns (uint256) {
        return 0;
    }

    /// @notice Called by the Juicebox contracts to see if the next ruleset gets the green light
    /// @param projectId The project whose queue is being advanced
    /// @param start The timestamp when that ruleset would begin
    function approvalStatusOf(
        uint256 projectId,
        uint256 /* rulesetId */,
        uint256 start
    ) external view override returns (JBApprovalStatus) {
        uint256 currentFunding = _totalFunding(terminal, projectId);
        if (currentFunding >= fundingGoal && block.timestamp >= deadline) {
            return JBApprovalStatus.Approved;
        } else {
            return JBApprovalStatus.Failed;
        }
    }

    /// @dev Juicebox and ERC165 interface support
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IJBRulesetApprovalHook).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /// @dev Pulls the project’s balance from the Juicebox terminal store
    function _totalFunding(address _terminal, uint256 projectId)
        internal
        view
        returns (uint256)
    {
        return jbTerminalStore.balanceOf(
            _terminal,
            projectId,
            JBConstants.NATIVE_TOKEN
        );
    }
}


// WIP : still needs to be tested

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IJBPayHook} from "@nana-core/interfaces/IJBPayHook.sol";
import {JBAfterPayRecordedContext} from "@nana-core/structs/JBAfterPayRecordedContext.sol";
import {JBRulesetConfig, JBTerminalConfig} from "@nana-core/structs/JBRulesetConfig.sol";
import {MissionCreator} from "./MissionCreator.sol";
/// A pay hook that handles post-payment logic for missions
contract MissionPayHook is IJBPayHook, Ownable {

    IJBController public jbController;
    
    mapping(uint256 => uint256) public projectVolumes;      // projectId => total volume
    mapping(uint256 => uint256) public projectFundingGoals; // projectId => funding goal
    mapping(address => bool) public operators;

    event VolumeUpdated(uint256 projectId, uint256 volume);
    event ProjectCompleted(uint256 projectId);


    constructor(address _jbMultiTerminal, address _missionCreator) Ownable(msg.sender) {
        jbMultiTerminalAddress = _jbMultiTerminal;
        missionCreator = MissionCreator(_missionCreator);
        operators[_jbMultiTerminal] = true;
    }

    modifier onlyOperators() {
        if (msg.sender != owner() && !operators[msg.sender]) {
            revert("Only an operator of the MissionPayHook can call this function");
        }
        _;
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }

    function setJBController(address _jbController) external onlyOwner {
        jbController = IJBController(_jbController);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IJBPayHook).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function afterPayRecordedWith(JBAfterPayRecordedContext calldata context) external payable onlyOperators {
        projectVolumes[context.projectId] += context.amount.value;
        emit VolumeUpdated(context.projectId, projectVolumes[context.projectId]);

        if (projectVolumes[context.projectId] >= missionCreator.missionFundingGoals(context.projectId) && 
            missionCreator.missionFundingGoals(context.projectId) != 0) {
            
            missionCreator.closeMission(context.projectId);
            
            emit ProjectCompleted(context.projectId);
        }
    }
}

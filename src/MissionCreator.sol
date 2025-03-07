// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {MissionTable} from "./tables/MissionTable.sol";
import {MoonDAOTeam} from "./ERC5643.sol";
import {IJBController} from "@nana-core/interfaces/IJBController.sol";
import {IJBProjects} from "@nana-core/interfaces/IJBProjects.sol";
import {Cycle1ApprovalHook, RefundTrapApprovalHook, Cycle2ApprovalHook, Cycle3ApprovalHook} from "./JuiceboxHooks.sol"; import {IJBToken} from "@nana-core/interfaces/IJBToken.sol";
import {JBRulesetConfig} from "@nana-core/structs/JBRulesetConfig.sol";
import {JBRulesetMetadata} from "@nana-core/structs/JBRulesetMetadata.sol";
import {JBSplitGroup} from "@nana-core/structs/JBSplitGroup.sol";
import {JBSplit} from "@nana-core/structs/JBSplit.sol";
import {JBFundAccessLimitGroup} from "@nana-core/structs/JBFundAccessLimitGroup.sol";
import {JBCurrencyAmount} from "@nana-core/structs/JBCurrencyAmount.sol";
import {JBAccountingContext} from "@nana-core/structs/JBAccountingContext.sol";
import {JBTerminalConfig} from "@nana-core/structs/JBTerminalConfig.sol";
import {IJBMultiTerminal} from "@nana-core/interfaces/IJBMultiTerminal.sol";
import {IJBRulesetApprovalHook} from "@nana-core/interfaces/IJBRulesetApprovalHook.sol";
import {IJBSplitHook} from "@nana-core/interfaces/IJBSplitHook.sol";
import {IJBTerminal} from "@nana-core/interfaces/IJBTerminal.sol";
contract MissionCreator is Ownable, IERC721Receiver {
    IJBController public jbController;
    IJBProjects public jbProjects;
    address public jbMultiTerminalAddress;
    address public jbDirectoryAddress;
    address public jbTerminalStoreAddress;
    MoonDAOTeam public moonDAOTeam;
    MissionTable public missionTable;
    address public moonDAOTreasury;

    event MissionCreated(uint256 indexed id, uint256 indexed teamId, uint256 indexed projectId, address tokenAddress, uint256 duration, uint256 fundingGoal);

    constructor(address _jbController, address _jbMultiTerminal, address _jbProjects, address _jbDirectory, address _jbTerminalStore, address _moonDAOTeam, address _missionTable, address _moonDAOTreasury) Ownable(msg.sender) {
        jbController = IJBController(_jbController);
        jbProjects = IJBProjects(_jbProjects);
        jbMultiTerminalAddress = _jbMultiTerminal;
        jbTerminalStoreAddress = _jbTerminalStore;
        jbDirectoryAddress = _jbDirectory;
        moonDAOTeam = MoonDAOTeam(_moonDAOTeam);
        missionTable = MissionTable(_missionTable);
        moonDAOTreasury = payable(_moonDAOTreasury);
    }

    function setJBController(address _jbController) external onlyOwner {
        jbController = IJBController(_jbController);
    }

    function setJBProjects(address _jbProjects) external onlyOwner {
        jbProjects = IJBProjects(_jbProjects);
    }

    function setJBMultiTerminal(address _jbMultiTerminal) external onlyOwner {
        jbMultiTerminalAddress = _jbMultiTerminal;
    }

    function setMoonDAOTreasury(address _moonDAOTreasury) external onlyOwner {
        moonDAOTreasury = _moonDAOTreasury;
    }   

    function setMoonDAOTeam(address _moonDAOTeam) external onlyOwner {
        moonDAOTeam = MoonDAOTeam(_moonDAOTeam);
    }

    function setMissionTable(address _missionTable) external onlyOwner {
        missionTable = MissionTable(_missionTable);
    }

    function createMission(uint256 teamId, address to, string calldata projectUri, uint32 duration, uint256 deadline, uint256 minFundingRequired, uint256 fundingGoal, bool token, string calldata tokenName, string calldata tokenSymbol, string calldata memo) external returns (uint256) {

        if(msg.sender != owner()) {
            require(moonDAOTeam.isManager(teamId, msg.sender), "Only a manager of the team or owner of the contract can create a mission.");
        }

        address payable toPayable = payable(to);
        address payable moonDAOTreasuryPayable = payable(moonDAOTreasury);
        Cycle1ApprovalHook cycle1ApprovalHook = new Cycle1ApprovalHook(minFundingRequired, fundingGoal, deadline, duration, jbDirectoryAddress, jbTerminalStoreAddress);
        RefundTrapApprovalHook refundTrapApprovalHook = new RefundTrapApprovalHook(minFundingRequired, fundingGoal, deadline, duration, jbDirectoryAddress, jbTerminalStoreAddress);
        Cycle2ApprovalHook cycle2ApprovalHook = new Cycle2ApprovalHook(minFundingRequired, fundingGoal, deadline, duration, jbDirectoryAddress, jbTerminalStoreAddress);
        Cycle3ApprovalHook cycle3ApprovalHook = new Cycle3ApprovalHook(minFundingRequired, fundingGoal, deadline, duration, jbDirectoryAddress, jbTerminalStoreAddress);

        IJBTerminal terminal = IJBTerminal(jbMultiTerminalAddress);

        //TODO: Configure ruleset
        JBRulesetConfig[] memory rulesetConfigurations = new JBRulesetConfig[](4);
        JBSplitGroup[] memory splitGroups = new JBSplitGroup[](2);
        //TODO: Configure split groups
        splitGroups[0] = JBSplitGroup({
            groupId: 0xEEEe, // This is the group ID of splits for ETH payouts. Ensure this is a uint256
            // Any leftover split percent amount after all with the group are taken into account will go to the project owner.
            splits: new JBSplit[](2) // Initialize as dynamic array
        });
        splitGroups[0].splits[0] = JBSplit({
            percent: 100_000_000, // 10%, out of 1_000_000_000
            projectId: 0, // Not used.
            preferAddToBalance: false, // Not used, since projectId is 0.
            beneficiary: moonDAOTreasuryPayable, // MoonDAO treasury
            lockedUntil: 0, // The split is not locked, meaning the project owner can remove it or change it at any time.
            hook: IJBSplitHook(address(0)) // Not used.
        });
        splitGroups[0].splits[1] = JBSplit({
            percent: 900_000_000, // 90%, out of 1_000_000_000
            projectId: 0, // Not used.
            preferAddToBalance: false, // Not used, since projectId is 0.
            beneficiary: toPayable, // Team multisig
            lockedUntil: 0, // The split is not locked, meaning the project owner can remove it or change it at any time.
            hook: IJBSplitHook(address(0)) // Not used.
        });
        splitGroups[1] = JBSplitGroup({
            groupId: 1, // This is the group ID of splits for reserved token distribution. 
            // Any leftover split percent amount after all with the group are taken into account will go to the project owner.
            splits: new JBSplit[](2) // Initialize as dynamic array
        });
        splitGroups[1].splits[0] = JBSplit({
            percent: 100_000_000, // 10%, out of 1_000_000_000
            projectId: 0, // Not used.
            preferAddToBalance: false, // Not used, since projectId is 0.
            beneficiary: moonDAOTreasuryPayable, // The beneficiary of the split.
            lockedUntil: 0, // The split is not locked, meaning the project owner can remove it or change it at any time.
            hook: IJBSplitHook(address(0)) // Not used.
        });
        splitGroups[1].splits[1] = JBSplit({
            percent: 300_000_000, // 30%, out of 1_000_000_000
            projectId: 420, // The projectId of the project to send the split to.
            preferAddToBalance: false, // The payment will go to the `pay` function of the project's primary terminal, not the `addToBalanceOf` function.
            beneficiary: toPayable, // The beneficiary of the payment made to the project's primary terminal. This is the address that will receive the project's tokens issued from the payment.
            lockedUntil: 0, // The split is not locked, meaning the project owner can remove it or change it at any time.
            hook: IJBSplitHook(address(0)) // Not used.
        });

        JBFundAccessLimitGroup[] memory fundAccessLimitGroups = new JBFundAccessLimitGroup[](1);

        //TODO: Add fund access limit groups
        fundAccessLimitGroups[0] = JBFundAccessLimitGroup({
            terminal: jbMultiTerminalAddress, // The terminal to create access limit rules for. Use the address directly.
            token: address(0xEEEe), // Ensure this is a valid token address
            payoutLimits: new JBCurrencyAmount[](2), // Initialize as dynamic array
            surplusAllowances: new JBCurrencyAmount[](1) // Initialize as dynamic array
        });

        //TODO: Add payout limits
        fundAccessLimitGroups[0].payoutLimits[0] = JBCurrencyAmount({
            amount: 6_900_000_000_000_000_000, // 6.9 USD worth of ETH can be paid out.
            currency: 1 // USD 
        });
        fundAccessLimitGroups[0].payoutLimits[1] = JBCurrencyAmount({
            amount: 4_200_000_000_000_000_000, // 4.2 ETH can be paid out.
            currency: 61166 // ETH
        });

        //TODO: Add surplus allowances
        fundAccessLimitGroups[0].surplusAllowances[0] = JBCurrencyAmount({
            amount: 700_000_000_000_000_000_000, // 700 USD worth of ETH can be used by the project owner discretionarily from the project's surplus.
            currency: 1 // USD
        });

        JBRulesetMetadata memory metadata = JBRulesetMetadata({
            reservedPercent: 5_000, // 50% of tokens are reserved, to be split according to the `splitGroups` property below.
            cashOutTaxRate: 0, // 0% tax on cashouts.
            baseCurrency: 61166, // ETH currency. Together with the `weight` property, this determines how many tokens are issued per ETH received. If the project receives a different token, say USDC, a price feed will determine the ETH value of the USDC at the time of the transaction in order to determine how many tokens are issued per USDC received.
            pausePay: false, // Payouts are not paused.
            pauseCreditTransfers: false, // Credit transfers are not paused.
            allowOwnerMinting: false, // The project owner cannot mint new tokens.
            allowSetCustomToken: false, // The project cannot set a custom token.
            allowTerminalMigration: false, // The project cannot move funds between terminals.
            allowSetTerminals: false, // The project cannot set new terminals.
            allowSetController: false, // The project cannot set a new controller.
            allowAddAccountingContext: false, // The project cannot add new accounting contexts to its terminals.
            allowAddPriceFeed: false, // The project cannot add new price feeds.
            ownerMustSendPayouts: false, // Anyone can send this project's payouts to the splits specified in the `splitGroups` property below.
            holdFees: false, // Fees are not held.
            useTotalSurplusForCashOuts: false, // Cash outs are made from each terminal independently.
            useDataHookForPay: false, // The project does not use a data hook for payouts.
            useDataHookForCashOut: false, // The project does not use a data hook for cashouts.
            dataHook: address(0), // No data hook contract is attached to this ruleset.
            metadata: 0 // No metadata is attached to this ruleset.
        });
        JBRulesetMetadata memory pausePayMetadata = JBRulesetMetadata({
            reservedPercent: 5_000, // 50% of tokens are reserved, to be split according to the `splitGroups` property below.
            cashOutTaxRate: 0, // 0% tax on cashouts.
            baseCurrency: 61166, // ETH currency. Together with the `weight` property, this determines how many tokens are issued per ETH received. If the project receives a different token, say USDC, a price feed will determine the ETH value of the USDC at the time of the transaction in order to determine how many tokens are issued per USDC received.
            pausePay: true, // Payouts are not paused.
            pauseCreditTransfers: false, // Credit transfers are not paused.
            allowOwnerMinting: false, // The project owner cannot mint new tokens.
            allowSetCustomToken: false, // The project cannot set a custom token.
            allowTerminalMigration: false, // The project cannot move funds between terminals.
            allowSetTerminals: false, // The project cannot set new terminals.
            allowSetController: false, // The project cannot set a new controller.
            allowAddAccountingContext: false, // The project cannot add new accounting contexts to its terminals.
            allowAddPriceFeed: false, // The project cannot add new price feeds.
            ownerMustSendPayouts: false, // Anyone can send this project's payouts to the splits specified in the `splitGroups` property below.
            holdFees: false, // Fees are not held.
            useTotalSurplusForCashOuts: false, // Cash outs are made from each terminal independently.
            useDataHookForPay: false, // The project does not use a data hook for payouts.
            useDataHookForCashOut: false, // The project does not use a data hook for cashouts.
            dataHook: address(0), // No data hook contract is attached to this ruleset.
            metadata: 0 // No metadata is attached to this ruleset.
        });
        rulesetConfigurations[0] = JBRulesetConfig({
            mustStartAtOrAfter: 0, // A 0 timestamp means the ruleset will start right away, or as soon as possible if there are already other rulesets queued.
            duration: duration, // A duration of 0 means the ruleset will last indefinitely until the next ruleset is queued. Any non-zero value would be the number of seconds this ruleset will last before the next ruleset is queued. If no new rulesets are queued, this ruleset will cycle over to another period with the same duration.
            weight: 2_000_000_000_000_000_000_000_000, // 1,000,000 tokens issued per unit of `baseCurrency` set below.
            weightCutPercent: 0, // 0% weight cut. If the `duration` property above is set to a non-zero value, the `weightCutPercent` property will be used to determine how much of the weight is cut from this ruleset to the next cycle.
            approvalHook: cycle1ApprovalHook, // No approval hook contract is attached to this ruleset, meaning new rulesets can be queued at any time and will take effect as soon as possible given the current ruleset's `duration`.
            metadata: metadata,
            splitGroups: splitGroups, // Initialize as dynamic array
            fundAccessLimitGroups: fundAccessLimitGroups // Initialize as dynamic array
        });

        rulesetConfigurations[1] = JBRulesetConfig({
            mustStartAtOrAfter: 0, // A 0 timestamp means the ruleset will start right away, or as soon as possible if there are already other rulesets queued.
            duration: duration, // A duration of 0 means the ruleset will last indefinitely until the next ruleset is queued. Any non-zero value would be the number of seconds this ruleset will last before the next ruleset is queued. If no new rulesets are queued, this ruleset will cycle over to another period with the same duration.
            weight: 0, // 0 tokens issued per unit of `baseCurrency` set below.
            weightCutPercent: 0, // 0% weight cut. If the `duration` property above is set to a non-zero value, the `weightCutPercent` property will be used to determine how much of the weight is cut from this ruleset to the next cycle.
            approvalHook: refundTrapApprovalHook, // No approval hook contract is attached to this ruleset, meaning new rulesets can be queued at any time and will take effect as soon as possible given the current ruleset's `duration`.
            metadata: pausePayMetadata,
            splitGroups: splitGroups, // Initialize as dynamic array
            fundAccessLimitGroups: fundAccessLimitGroups // Initialize as dynamic array
        });
        rulesetConfigurations[2] = JBRulesetConfig({
            mustStartAtOrAfter: 0, // A 0 timestamp means the ruleset will start right away, or as soon as possible if there are already other rulesets queued.
            duration: duration, // A duration of 0 means the ruleset will last indefinitely until the next ruleset is queued. Any non-zero value would be the number of seconds this ruleset will last before the next ruleset is queued. If no new rulesets are queued, this ruleset will cycle over to another period with the same duration.
            weight: 1_000_000_000_000_000_000_000_000, // 1,000,000 tokens issued per unit of `baseCurrency` set below.
            weightCutPercent: 0, // 0% weight cut. If the `duration` property above is set to a non-zero value, the `weightCutPercent` property will be used to determine how much of the weight is cut from this ruleset to the next cycle.
            approvalHook: cycle2ApprovalHook, // No approval hook contract is attached to this ruleset, meaning new rulesets can be queued at any time and will take effect as soon as possible given the current ruleset's `duration`.
            metadata: metadata,
            splitGroups: splitGroups, // Initialize as dynamic array
            fundAccessLimitGroups: fundAccessLimitGroups // Initialize as dynamic array
        });
        rulesetConfigurations[3] = JBRulesetConfig({
            mustStartAtOrAfter: 0, // A 0 timestamp means the ruleset will start right away, or as soon as possible if there are already other rulesets queued.
            duration: duration, // A duration of 0 means the ruleset will last indefinitely until the next ruleset is queued. Any non-zero value would be the number of seconds this ruleset will last before the next ruleset is queued. If no new rulesets are queued, this ruleset will cycle over to another period with the same duration.
            weight: 500_000_000_000_000_000_000_000, // 1,000,000 tokens issued per unit of `baseCurrency` set below.
            weightCutPercent: 0, // 0% weight cut. If the `duration` property above is set to a non-zero value, the `weightCutPercent` property will be used to determine how much of the weight is cut from this ruleset to the next cycle.
            approvalHook: cycle3ApprovalHook, // No approval hook contract is attached to this ruleset, meaning new rulesets can be queued at any time and will take effect as soon as possible given the current ruleset's `duration`.
            metadata: metadata,
            splitGroups: splitGroups, // Initialize as dynamic array
            fundAccessLimitGroups: fundAccessLimitGroups // Initialize as dynamic array
        });

        //TODO: Add terminal configurations
        JBTerminalConfig[] memory terminalConfigurations = new JBTerminalConfig[](1);
        terminalConfigurations[0] = JBTerminalConfig({
            terminal: terminal, // A terminal to access funds through. Cast to IJBMultiTerminal
            // The tokens to accept through the given terminal, and how they should be accounted for.
            accountingContextsToAccept: new JBAccountingContext[](1) // Initialize as dynamic array
        });
        terminalConfigurations[0].accountingContextsToAccept[0] = JBAccountingContext({
            token: address(0xEEEe), // The token to accept through the given terminal. Ensure this is a valid token address
            decimals: 18, // The number of decimals the token is accounted with as a fixed point number.
            currency: 61166 // The currency used with the token is ETH. This ensures proper price conversion when necessary.
        });

        uint256 projectId = jbController.launchProjectFor(
            address(this),
            projectUri,
            rulesetConfigurations,
            terminalConfigurations,
            memo
        );

        address tokenAddress = address(0);
        if(token){
            tokenAddress = address(jbController.deployERC20For(projectId, tokenName, tokenSymbol, 0));
        }
        
        jbProjects.safeTransferFrom(address(this), to, projectId);

        uint256 missionId = missionTable.insertIntoTable(teamId, projectId, fundingGoal);

        emit MissionCreated(missionId, teamId, projectId, tokenAddress, duration, fundingGoal);

        return missionId;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}




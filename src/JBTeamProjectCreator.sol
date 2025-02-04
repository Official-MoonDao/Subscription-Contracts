// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MoonDAOTeam} from "./ERC5643.sol";
import {IJBController} from "@nana-core/interfaces/IJBController.sol";
import {JBRulesetConfig} from "@nana-core/structs/JBRulesetConfig.sol";
import {JBRulesetMetadata} from "@nana-core/structs/JBRulesetMetadata.sol";
import {JBSplitGroup} from "@nana-core/structs/JBSplitGroup.sol";
import {JBSplit} from "@nana-core/structs/JBSplit.sol";
import {JBFundAccessLimitGroup} from "@nana-core/structs/JBFundAccessLimitGroup.sol";
import {JBCurrencyAmount} from "@nana-core/structs/JBCurrencyAmount.sol";
import {JBAccountingContext} from "@nana-core/structs/JBAccountingContext.sol";
import {JBTerminalConfig} from "@nana-core/structs/JBTerminalConfig.sol";
import {IJBMultiTerminal} from "@nana-core/interfaces/IJBMultiTerminal.sol";

contract JBTeamProjectCreator is Ownable {
    IJBController public jbController;
    address public jbMultiTerminalAddress;
    MoonDAOTeam public moonDAOTeam;
    JBTeamProjectsTable public jbTeamProjectsTable;
    address public moonDAOTreasury;

    event ProjectCreated(uint256 indexed id, uint256 indexed teamId);

    constructor(address _jbController, address _jbMultiTerminal, address _moonDAOTeam, address _jbTeamProjectsTable, address _moonDAOTreasury) Ownable(msg.sender) {
        jbController = IJBController(_jbController);
        jbMultiTerminalAddress = _jbMultiTerminal;
        moonDAOTeam = MoonDAOTeam(_moonDAOTeam);
        jbTeamProjectsTable = JBTeamProjectsTable(_jbTeamProjectsTable);
        moonDAOTreasury = _moonDAOTreasury;
    }

    function setJBController(address _jbController) external onlyOwner {
        jbController = IJBController(_jbController);
    }

    function setJBMultiTerminal(address _jbMultiTerminal) external onlyOwner {
        jbMultiTerminalAddress = _jbMultiTerminal;
    }

    function setMoonDAOTreasury(address _moonDAOTreasury) external onlyOwner {
        moonDAOTreasury = _moonDAOTreasury;
    }

    function setMoonDaoTeam(address _moonDaoTeam) external onlyOwner {
        moonDaoTeam = MoonDAOTeam(_moonDaoTeam);
    }

    function setJBTeamProjectsTable(address _jbTeamProjectsTable) external onlyOwner {
        jbTeamProjectsTable = JBTeamProjectsTable(_jbTeamProjectsTable);
    }

    function createTeamProject(uint256 teamId, address to, string calldata projectUri, string calldata memo) external returns (uint256) {
        if(msg.sender != owner()) {
            require(moonDAOTeam.isManager(teamId, msg.sender), "Only manager of the team or owner of the contract can create a juicebox team project.");
        }

        JBRulesetConfig[] memory rulesetConfigurations = new JBRulesetConfig[](1);
        rulesetConfigurations[0] = JBRulesetConfig({
            mustStartAtOrAfter: 0, // A 0 timestamp means the ruleset will start right away, or as soon as possible if there are already other rulesets queued.
            duration: 0, // A duration of 0 means the ruleset will last indefinitely until the next ruleset is queued. Any non-zero value would be the number of seconds this ruleset will last before the next ruleset is queued. If no new rulesets are queued, this ruleset will cycle over to another period with the same duration.
            weight: 1_000_000_000_000_000_000_000_000, // 1,000,000 tokens issued per unit of `baseCurrency` set below.
            weightCutPercent: 0, // 0% weight cut. If the `duration` property above is set to a non-zero value, the `weightCutPercent` property will be used to determine how much of the weight is cut from this ruleset to the next cycle.
            approvalHook: 0x0000000000000000000000000000000000000000, // No approval hook contract is attached to this ruleset, meaning new rulesets can be queued at any time and will take effect as soon as possible given the current ruleset's `duration`.
            metadata: JBRulesetMetadata({
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
                dataHook: 0x0000000000000000000000000000000000000000, // No data hook contract is attached to this ruleset.
                metadata: 0 // No metadata is attached to this ruleset.
            }),
            splitGroups: [JBSplitGroup({
                groupId: 0x000000000000000000000000000000000000EEEe, // This is the group ID of splits for ETH payouts.
                // Any leftover split percent amount after all with the group are taken into account will go to the project owner.
                splits: [JBSplit({
                percent: 100_000_000, // 10%, out of 1_000_000_000
                projectId: 0, // Not used.
                preferAddToBalance: false, // Not used, since projectId is 0.
                beneficiary: moonDAOTreasury, // MoonDAO treasury
                lockedUntil: 0, // The split is not locked, meaning the project owner can remove it or change it at any time.
                hook: 0x0000000000000000000000000000000000000000 // Not used.
                }), JBSplit({
                percent: 900_000_000, // 90%, out of 1_000_000_000
                projectId: 0, // Not used.
                preferAddToBalance: false, // Not used, since projectId is 0.
                beneficiary: to, // Team multisig
                lockedUntil: 0, // The split is not locked, meaning the project owner can remove it or change it at any time.
                hook: 0x0000000000000000000000000000000000000000 // Not used.
                })]
            }), JBSplitGroup({
                groupId: 1, // This is the group ID of splits for reserved token distribution. 
                // Any leftover split percent amount after all with the group are taken into account will go to the project owner.
                splits: [JBSplit({
                percent: 100_000_000, // 10%, out of 1_000_000_000
                projectId: 0, // Not used.
                preferAddToBalance: false, // Not used, since projectId is 0.
                beneficiary: moonDAOTreasury, // The beneficiary of the split.
                lockedUntil: 0, // The split is not locked, meaning the project owner can remove it or change it at any time.
                hook: 0x0000000000000000000000000000000000000000 // Not used.
                }), JBSplit({
                percent: 300_000_000, // 30%, out of 1_000_000_000
                projectId: 420, // The projectId of the project to send the split to.
                preferAddToBalance: false, // The payment will go to the `pay` function of the project's primary terminal, not the `addToBalanceOf` function.
                beneficiary: to, // The beneficiary of the payment made to the project's primary terminal. This is the address that will receive the project's tokens issued from the payment.
                lockedUntil: 0, // The split is not locked, meaning the project owner can remove it or change it at any time.
                hook: 0x0000000000000000000000000000000000000000 // Not used.
                })] 
            })],
            // Below are the rules according to which funds can be accessed during this ruleset.
            fundAccessLimitGroups: [JBFundAccessLimitGroup({
                terminal: jbMultiTerminalAddress, // The terminal to create access limit rules for.
                token: 0x000000000000000000000000000000000000EEEe, // Rules for accessing ETH from the terminal.
                payoutLimits: [JBCurrencyAmount({
                amount: 4_200_000_000_000_000_000, // 4.2 ETH can be paid out.
                currency: 61166 // ETH
                }), JBCurrencyAmount({
                amount: 6_900_000_000_000_000_000, // 6.9 USD worth of ETH can be paid out.
                currency: 1 // USD 
                })],
                surplusAllowances: [JBCurrencyAmount({
                amount: 700_000_000_000_000_000_000, // 700 USD worth of ETH can be used by the project owner discretionarily from the project's surplus.
                currency: 1 // USD
                })]
            })]
        });

        JBTerminalConfig[] memory terminalConfigurations = new JBTerminalConfig[](1);
        terminalConfigurations[0] = JBTerminalConfig({
            terminal: jbMultiTerminalAddress, // A terminal to access funds through.
             // The tokens to accept through the given terminal, and how they should be accounted for.
            accountingContextsToAccept: [JBAccountingContext({
            token: 0x000000000000000000000000000000000000EEEe, // The token to accept through the given terminal.
            decimals: 18, // The number of decimals the token is accounted with as a fixed point number.
            currency: 61166 // The currency used with the token is ETH. This ensures proper price conversion when necessary.
            })]
        });
        
        uint256 projectId = jbController.launchProjectFor(
            to,
            projectUri,
            rulesetConfigurations,
            terminalConfigurations,
            memo
        );

        jbTeamProjectsTable.insertIntoTable(teamId, projectId);

        emit ProjectCreated(projectId, teamId);

        return projectId;
    }
}




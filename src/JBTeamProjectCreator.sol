// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MoonDAOTeam} from "./ERC5643.sol";

contract JBTeamProjectCreator is Ownable {
    IJBController public jbController;
    MoonDAOTeam public moonDaoTeam;
    JBTeamProjectsTable public jbTeamProjectsTable;

    event ProjectCreated(uint256 indexed id, uint256 indexed teamId);

    constructor(address _jbController, address _moonDaoTeam, address _jbTeamProjectsTable) Ownable(msg.sender) {
        jbController = IJBController(_jbController);
        moonDaoTeam = MoonDAOTeam(_moonDaoTeam);
        jbTeamProjectsTable = JBTeamProjectsTable(_jbTeamProjectsTable);
    }

    function setJBController(address _jbController) external onlyOwner {
        jbController = IJBController(_jbController);
    }

    function setMoonDaoTeam(address _moonDaoTeam) external onlyOwner {
        moonDaoTeam = MoonDAOTeam(_moonDaoTeam);
    }

    function setJBTeamProjectsTable(address _jbTeamProjectsTable) external onlyOwner {
        jbTeamProjectsTable = JBTeamProjectsTable(_jbTeamProjectsTable);
    }

    function createTeamProject(address owner) external returns (uint256) {
        if(msg.sender != owner()) {
            require(moonDaoTeam.isManager(teamId, msg.sender), "Only manager of the team or owner of the contract can create a juicebox team project.");
        }
        
        uint256 projectId = jbController.launchProjectFor(
            owner,
        );

        jbTeamProjectsTable.insertIntoTable(projectId, teamId);

        emit ProjectCreated(projectId, teamId);

        return projectId;
    }
}




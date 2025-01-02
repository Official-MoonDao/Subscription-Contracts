pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TablelandDeployments} from "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {TablelandController} from "@evm-tableland/contracts/TablelandController.sol";
import {SQLHelpers} from "@evm-tableland/contracts/utils/SQLHelpers.sol";
import {TablelandPolicy} from "@evm-tableland/contracts/TablelandPolicy.sol";
import {ProjectTeam} from "../ProjectTeam.sol";


contract Project is TablelandController, Ownable {
    // Table for storing project information for retroactive rewards
    // contributors is a json object with keys as contributor addresses
    // and values as the percentage of rewards
    uint256 private _tableId;
    string private _TABLE_PREFIX;
    ProjectTeam public _projectTeam;

    constructor(string memory _table_prefix) Ownable(msg.sender) {
        _TABLE_PREFIX = _table_prefix;
        _tableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id integer primary key,"
                "title text,"
                "quarter integer,"
                "year integer,"
                "MDP integer,"
                "proposalIPFS text,"
                "proposalLink text,"
                "finalReportIPFS text,"
                "finalReportLink text,"
                "contributors text,"
                "active integer,"
                "eligible integer",
                _TABLE_PREFIX
            )
        );
    }

    function setProjectTeam(address projectTeam) external onlyOwner{
        _projectTeam = ProjectTeam(projectTeam);
    }

    // Let anyone insert into the table
    function insertIntoTable(uint256 id, string memory title, uint256 quarter, uint256 year, uint256 MDP, string memory proposalIPFS, string memory proposalLink, string memory finalReportIPFS, string memory finalReportLink, string memory contributors, uint256 active, uint256 eligible) external {
        //only let projectTeam.projectTeamCreator insert
        require(_projectTeam.projectTeamCreator() == msg.sender, "Only ProjectTeamCreator can insert");
        string memory setters = string.concat(
                Strings.toString(id),
                ",",
                SQLHelpers.quote(title),
                ",",
                Strings.toString(quarter),
                ",",
                Strings.toString(year),
                ",",
                Strings.toString(MDP),
                ",",
                SQLHelpers.quote(proposalIPFS),
                ",",
                SQLHelpers.quote(proposalLink),
                ",",
                SQLHelpers.quote(finalReportIPFS),
                ",",
                SQLHelpers.quote(finalReportLink),
                ",",
                SQLHelpers.quote(contributors),
                ",",
                Strings.toString(active),
                ",",
                Strings.toString(eligible)
        );
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toInsert(
                _TABLE_PREFIX,
                _tableId,
                "id,title,quarter,year,MDP,proposalIPFS,proposalLink,finalReportIPFS,finalReportLink,contributors,active,eligible",
                setters
            )
        );
    }

    function updateTableCol(uint256 id, string memory col, string memory val) internal {
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toUpdate(
                _TABLE_PREFIX,
                _tableId,
                string.concat(
                    col,
                    "=",
                    SQLHelpers.quote(val)
                ),
                string.concat(
                    "id = ",
                    Strings.toString(id)
                )
            )
        );
    }

    function updateFinalReportIPFS(uint256 id, string memory finalReportIPFS) external {
        require (_projectTeam.isManager(id, msg.sender) || owner() == msg.sender, "Only Manager can update");
        updateTableCol(id, "finalReportIPFS", finalReportIPFS);
    }

    function updateQuarterAndYear(uint256 id, uint256 quarter, uint256 year) external {
        require (_projectTeam.isManager(id, msg.sender) || owner() == msg.sender, "Only Manager can update");
        updateTableCol(id, "quarter", Strings.toString(quarter));
        updateTableCol(id, "year", Strings.toString(year));
    }

    function updateContributors(uint256 id, string memory contributors) external {
        require (_projectTeam.isManager(id, msg.sender) || owner() == msg.sender, "Only Manager can update");
        updateTableCol(id, "contributors", contributors);
    }

    function updateActive(uint256 id, uint256 active) external onlyOwner{
        updateTableCol(id, "active", Strings.toString(active));
    }

    function updateEligible(uint256 id, uint256 eligible) external onlyOwner{
        updateTableCol(id, "eligible", Strings.toString(eligible));
    }


    // Set the ACL controller to enable row-level writes with dynamic policies
    function setAccessControl(address controller) external onlyOwner{
        TablelandDeployments.get().setController(
            address(this), // Table owner, i.e., this contract
            _tableId,
            controller // Set the controller address—a separate controller contract
        );
    }

    function getTableId() external view returns (uint256) {
        return _tableId;
    }

    function getTableName() external view returns (string memory) {
        return SQLHelpers.toNameFromId(_TABLE_PREFIX, _tableId);
    }

    function getPolicy(
        address caller,
        uint256
    ) public payable override returns (TablelandPolicy memory) {
        return
            TablelandPolicy({
                allowInsert: true,
                allowUpdate: true,
                allowDelete: true,
                whereClause: "",
                withCheck: "",
                updatableColumns: new string[](0)
            });

    }
}


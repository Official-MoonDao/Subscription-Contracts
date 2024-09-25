pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TablelandDeployments} from "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {TablelandController} from "@evm-tableland/contracts/TablelandController.sol";
import {SQLHelpers} from "@evm-tableland/contracts/utils/SQLHelpers.sol";
import {TablelandPolicy} from "@evm-tableland/contracts/TablelandPolicy.sol";
import {MoonDAOTeam} from "../ERC5643.sol";


contract Project is TablelandController, Ownable {
    uint256 private _tableId;
    string private _TABLE_PREFIX;
    uint256 public currId = 0;

    constructor(string memory _table_prefix) Ownable(msg.sender) {
        _TABLE_PREFIX = _table_prefix;
        _tableId = TablelandDeployments.get().create(
            // TODO set to this contract eg. address(this)
            address(msg.sender),
            SQLHelpers.toCreateFromSchema(
                "id integer primary key,"
                "title text,"
                "year integer,"
                "quarter integer,"
                "MPD integer,"
                "proposalIPFS text,"
                "finalReportIPFS text,"
                "allocation text",
                _TABLE_PREFIX
            )
        );
    }

    // Let anyone insert into the table
    function insertIntoTable(string memory title, uint256 year, uint256 quarter, uint256 MDP, string memory proposalIPFS, string memory finalReportIPFS, string memory allocation) external {
        string memory setters = string.concat(
                Strings.toString(currId), // Convert to a string
                ",",
                SQLHelpers.quote(title), // Wrap strings in single quotes with the `quote` method
                ",",
                Strings.toString(year),
                ",",
                Strings.toString(quarter),
                ",",
                Strings.toString(MDP),
                ",",
                SQLHelpers.quote(proposalIPFS), // Wrap strings in single quotes with the `quote` method
                ",",
                SQLHelpers.quote(finalReportIPFS), // Wrap strings in single quotes with the `quote` method
                ",",
                SQLHelpers.quote(allocation) // Wrap strings in single quotes with the `quote` method
        );
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toInsert(
                _TABLE_PREFIX,
                _tableId,
                "id,title,year,quarter,MDP,proposalIPFS,finalReportIPFS,allocation",
                setters
            )
        );
        currId += 1;
    }


    // Set the ACL controller to enable row-level writes with dynamic policies
    function setAccessControl(address controller) external onlyOwner{
        TablelandDeployments.get().setController(
            address(this), // Table owner, i.e., this contract
            _tableId,
            controller // Set the controller address—a separate controller contract
        );
    }

    // Return the table ID
    function getTableId() external view returns (uint256) {
        return _tableId;
    }

    // Return the table name
    function getTableName() external view returns (string memory) {
        return SQLHelpers.toNameFromId(_TABLE_PREFIX, _tableId);
    }

    function getPolicy(
        address caller,
        uint256
    ) public payable override returns (TablelandPolicy memory) {
        // TODO restrict access to only the owner
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


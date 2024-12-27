pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TablelandDeployments} from "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {TablelandController} from "@evm-tableland/contracts/TablelandController.sol";
import {SQLHelpers} from "@evm-tableland/contracts/utils/SQLHelpers.sol";
import {TablelandPolicy} from "@evm-tableland/contracts/TablelandPolicy.sol";


contract Competitor is TablelandController, Ownable {
    // Table for storing project information for retroactive rewards
    // contributors is a json object with keys as contributor addresses
    // and values as the percentage of rewards
    uint256 private _tableId;
    string private _TABLE_PREFIX;
    // mapping from deprizeId to current id
    mapping(uint256 => uint256) public deprizeIdToCurrId;
    // mapping from deprizeId to mapping from id to teamId
    mapping(uint256 => mapping(uint256 => uint256)) public deprizeIdToIdToTeamId;

    constructor(string memory _table_prefix) Ownable(msg.sender) {
        _TABLE_PREFIX = _table_prefix;
        _tableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id integer,"
                "deprize integer,"
                "teamId integer,"
                "metadata text,"
                "unique(deprize, teamId),"
                "PRIMARY KEY (id, deprize, teamId)",
                _TABLE_PREFIX
            )
        );
    }

    // Let anyone insert into the table
    function insertIntoTable(uint256 deprize, uint256 teamId, string memory metadata) external {
        uint256 currId = deprizeIdToCurrId[deprize];
        string memory setters = string.concat(
                Strings.toString(currId),
                ",",
                Strings.toString(deprize),
                ",",
                Strings.toString(teamId),
                ",",
                SQLHelpers.quote(metadata)
        );
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toInsert(
                _TABLE_PREFIX,
                _tableId,
                "id,deprize,teamId,metadata",
                setters
            )
        );
        deprizeIdToCurrId[deprize] = currId + 1;
        deprizeIdToIdToTeamId[deprize][currId] = teamId;
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


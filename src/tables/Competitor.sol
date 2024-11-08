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
    uint256 public currId = 0;

    constructor(string memory _table_prefix) Ownable(msg.sender) {
        _TABLE_PREFIX = _table_prefix;
        _tableId = TablelandDeployments.get().create(
            address(msg.sender),
            SQLHelpers.toCreateFromSchema(
                "id integer primary key,"
                "name text,"
                "deprize integer,"
                "treasury text,"
                "metadata text",
                _TABLE_PREFIX
            )
        );
    }

    // Let anyone insert into the table
    function insertIntoTable(string memory name, uint256 deprize, string memory treasury, string memory metadata) external {
        string memory setters = string.concat(
                Strings.toString(currId),
                ",",
                SQLHelpers.quote(name),
                ",",
                Strings.toString(deprize),
                ",",
                SQLHelpers.quote(treasury),
                ",",
                SQLHelpers.quote(metadata)
        );
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toInsert(
                _TABLE_PREFIX,
                _tableId,
                "id,name,deprize,treasury,metadata",
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


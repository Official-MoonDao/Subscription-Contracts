pragma solidity >=0.8.11 <0.9.0;

import "@evm-tableland/contracts/interfaces/ITablelandTables.sol";
import "@evm-tableland/contracts/interfaces/ITablelandController.sol";
import "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {SQLHelpers} from "@evm-tableland/contracts/utils/SQLHelpers.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract DePrizeDistribution is ERC721Holder, Ownable {
    // Table for storing retroactive rewards votes.
    // distribution is a json object with keys being project id
    // from the project table and values being the percent
    // allocated to that project.
    using ERC165Checker for address;

    uint256 private _tableId;
    string private _TABLE_PREFIX;
    string private constant DEPRIZE_VOTE_SCHEMA =
        "id integer primary key, deprize integer, timestamp integer, address text, distribution text";

    constructor(string memory _table_prefix) Ownable(msg.sender)  {
        _TABLE_PREFIX = _table_prefix;
        _tableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(DEPRIZE_VOTE_SCHEMA, _TABLE_PREFIX)
        );
    }

    function insertIntoTable(uint256 deprize, string memory distribution) external {        
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toInsert(
                _TABLE_PREFIX,
                _tableId,
                "deprize,timestamp,address,distribution",
                string.concat(
                    Strings.toString(deprize),
                    ",",
                    Strings.toString(block.timestamp),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(msg.sender)),
                    ",",
                    "json(",
                    SQLHelpers.quote(distribution),
                    ")"
                )
            )
        );
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

}
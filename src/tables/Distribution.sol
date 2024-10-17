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

contract Distribution is ERC721Holder, Ownable {
    using ERC165Checker for address;

    uint256 private _tableId;
    string private _TABLE_PREFIX;
    string private constant DISTRIBUTIONS_SCHEMA =
        "id integer primary key, quarter integer, year integer, address text, distribution text, unique(quarter, year, address)";

    constructor(string memory _table_prefix) Ownable(msg.sender)  {
        _TABLE_PREFIX = _table_prefix;
        _tableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(DISTRIBUTIONS_SCHEMA, _TABLE_PREFIX)
        );
    }

    // Create an distribution for a given quarter and year.
    function insertIntoTable(uint256 quarter, uint256 year, string memory distribution) external {
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toInsert(
                _TABLE_PREFIX,
                _tableId,
                "quarter,year,address,distribution",
                string.concat(
                    Strings.toString(quarter),
                    ",",
                    Strings.toString(year),
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

    function updateTableCol(uint256 quarter, uint256 year, string memory distribution) external {
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toUpdate(
                _TABLE_PREFIX,
                _tableId,
                string.concat(
                "distribution=",
                    "json(",
                    SQLHelpers.quote(distribution),
                    ")"
                ),
                string.concat(
                    "quarter = ",
                    Strings.toString(quarter),
                    " AND year = ",
                    Strings.toString(year),
                    " AND address = ",
                    SQLHelpers.quote(Strings.toHexString(msg.sender))
                )
            )
        );
    }

    // Delete a row from the table by quarter and year
    function deleteFromTable(uint256 quarter, uint256 year) external {
        TablelandDeployments.get().mutate(
            address(this),
            _tableId,
            SQLHelpers.toDelete(_TABLE_PREFIX, _tableId,
                string.concat(
                    "quarter = ",
                    Strings.toString(quarter),
                    " AND year = ",
                    Strings.toString(year),
                    " AND address = ",
                    SQLHelpers.quote(Strings.toHexString(msg.sender))
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

    // Return the table ID
    function getTableId() external view returns (uint256) {
        return _tableId;
    }

    // Return the table name
    function getTableName() external view returns (string memory) {
        return SQLHelpers.toNameFromId(_TABLE_PREFIX, _tableId);
    }

}

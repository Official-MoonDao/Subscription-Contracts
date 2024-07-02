pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TablelandDeployments} from "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {SQLHelpers} from "@evm-tableland/contracts/utils/SQLHelpers.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {MoonDAOTeam} from "../ERC5643.sol";


contract MarketplaceTable is ERC721Holder, Ownable {
    uint256 private _tableId;
    string private _TABLE_PREFIX;
    MoonDAOTeam public _moonDaoTeam;
    uint256 public currId = 0;
    mapping(uint256 => uint256) public idToTeamId;

    constructor(string memory _table_prefix) Ownable(msg.sender) {
        _TABLE_PREFIX = _table_prefix;
        _tableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id integer primary key,"
                "title text,"
                "description text,"
                "image text,"
                "teamId integer,"
                "price integer,"
                "currency text,"
                "shipping text",
                _TABLE_PREFIX
            )
        );
    }

    function setMoonDaoTeam(address moonDaoTeam) external onlyOwner{
        _moonDaoTeam = MoonDAOTeam(moonDaoTeam);
    }

    // Let anyone insert into the table
    function insertIntoTable(string memory title, string memory description, string memory image, uint256 teamId, uint256 price, string memory currency, string memory shipping) external {
        require (_moonDaoTeam.isManager(teamId, msg.sender) || owner() == msg.sender, "Only Admin can update");
        string memory setters = string.concat(
                Strings.toString(currId), // Convert to a string
                ",",
                SQLHelpers.quote(title), // Wrap strings in single quotes with the `quote` method
                ",",
                SQLHelpers.quote(description), // Wrap strings in single quotes with the `quote` method
                ",",
                SQLHelpers.quote(image), // Wrap strings in single quotes with the `quote` method
                ",",
                Strings.toString(teamId),
                ",",
                Strings.toString(price), // Wrap strings in single quotes with the `quote` method
                ",",
                SQLHelpers.quote(currency), // Wrap strings in single quotes with the `quote` method
                ",",
                SQLHelpers.quote(shipping) // Wrap strings in single quotes with the `quote` method
        );
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toInsert(
                _TABLE_PREFIX,
                _tableId,
                "id,title,description,image,teamId,price,currency,shipping",
                setters
            )
        );
        idToTeamId[currId] = teamId;
        currId += 1;
    }

    function updateTable(uint256 id, string memory title, string memory description, string memory image, uint256 teamId, uint256 price, string memory currency, string memory shipping) external {
        
        require (_moonDaoTeam.isManager(teamId, msg.sender) || owner() == msg.sender, "Only Admin can update");
        require (idToTeamId[id] == teamId, "You can only update a marketplace listing by your team");

        // Set the values to update
        string memory setters = string.concat(
            "title=",
            SQLHelpers.quote(title),
            ",description=",
            SQLHelpers.quote(description),
            ",image=",
            SQLHelpers.quote(image),
            ",price=",
            Strings.toString(price),
            ",currency=",
            SQLHelpers.quote(currency),
            ",shipping=",
            SQLHelpers.quote(shipping)
        );
        // Specify filters for which row to update
        string memory filters = string.concat(
            "id=",
            Strings.toString(id)
        );
        // Mutate a row at `id` with a new `val`
        TablelandDeployments.get().mutate(
            address(this),
            _tableId,
            SQLHelpers.toUpdate(_TABLE_PREFIX, _tableId, setters, filters)
        );
    }

    // Update only the row that the caller inserted
    function updateTableCol(uint256 id, uint256 teamId, string memory colName, string memory val) external {
        require (Strings.equal(colName, "id"), "Cannot update id");
        require (Strings.equal(colName, "teamId"), "Cannot update teamId");
        require (_moonDaoTeam.isManager(teamId, msg.sender) || owner() == msg.sender, "Only Admin can update");

        // Set the values to update
        string memory setters = string.concat(colName, "=", SQLHelpers.quote(val));
        // Specify filters for which row to update
        string memory filters = string.concat(
            "id=",
            Strings.toString(id)
        );
        // Mutate a row at `id` with a new `val`
        TablelandDeployments.get().mutate(
            address(this),
            _tableId,
            SQLHelpers.toUpdate(_TABLE_PREFIX, _tableId, setters, filters)
        );
    }


    // Delete a row from the table by ID 
    function deleteFromTable(uint256 id, uint256 teamId) external {
        require (_moonDaoTeam.isManager(teamId, msg.sender) || owner() == msg.sender, "Only Admin can update");
        require (idToTeamId[id] == teamId, "You can only delete a marketplace listing by your team");

        // Specify filters for which row to delete
        string memory filters = string.concat(
            "id=",
            Strings.toString(id)
        );
        // Mutate a row at `id`
        TablelandDeployments.get().mutate(
            address(this),
            _tableId,
            SQLHelpers.toDelete(_TABLE_PREFIX, _tableId, filters)
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
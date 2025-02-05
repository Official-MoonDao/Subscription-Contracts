pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TablelandDeployments} from "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {SQLHelpers} from "@evm-tableland/contracts/utils/SQLHelpers.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {MoonDAOTeam} from "../ERC5643.sol";


contract JBTeamProjectTable is ERC721Holder, Ownable {
    uint256 private _tableId;
    string private _TABLE_PREFIX;
    MoonDAOTeam public _moonDaoTeam;
    uint256 public currId = 0;
    mapping(uint256 => uint256) public idToTeamId;
    address public jbTeamProjectCreator;

    event ProjectInserted(uint256 indexed id, uint256 indexed teamId);
    event ProjectUpdated(uint256 indexed id, uint256 indexed teamId);
    event ProjectDeleted(uint256 indexed id, uint256 indexed teamId);

    modifier onlyOperators() {
        require(msg.sender == owner() || msg.sender == jbTeamProjectCreator, "Only Owner or Creator can call this function");
        _;
    }

    constructor(string memory _table_prefix, address _jbTeamProjectCreator) Ownable(msg.sender) {
        _TABLE_PREFIX = _table_prefix;
        jbTeamProjectCreator = _jbTeamProjectCreator;
        _tableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id integer primary key,"
                "projectId integer,"
                "teamId integer",
                _TABLE_PREFIX
            )
        );
    }

    function setMoonDaoTeam(address moonDaoTeam) external onlyOwner{
        _moonDaoTeam = MoonDAOTeam(moonDaoTeam);
    }

    function setJBTeamProjectCreator(address _jbTeamProjectCreator) external onlyOwner{
        jbTeamProjectCreator = _jbTeamProjectCreator;
    }

    function addColumn(string memory columnName, string memory columnType) external onlyOwner {
        string memory alterStatement = string.concat(
            "ALTER TABLE ",
            SQLHelpers.toNameFromId(_TABLE_PREFIX, _tableId),
            " ADD COLUMN ",
            columnName,
            " ",
            columnType
        );

        TablelandDeployments.get().mutate(
            address(this),
            _tableId,
            alterStatement
        );
    }

    function deleteColumn(string memory columnName) external onlyOwner {
        string memory alterStatement = string.concat(
            "ALTER TABLE ",
            SQLHelpers.toNameFromId(_TABLE_PREFIX, _tableId),
            " DROP COLUMN ",
            columnName
        );

        TablelandDeployments.get().mutate(
            address(this),
            _tableId,
            alterStatement
        );
    }

    function insertIntoTable(uint256 teamId, uint256 projectId) external onlyOperators {
        string memory setters = string.concat(
                Strings.toString(currId),
                ",",
                Strings.toString(projectId),
                ",",
                Strings.toString(teamId)
        );
        TablelandDeployments.get().mutate(
            address(this), // Table owner, i.e., this contract
            _tableId,
            SQLHelpers.toInsert(
                _TABLE_PREFIX,
                _tableId,
                "id,projectId,teamId",
                setters
            )
        );
        idToTeamId[currId] = teamId;
        emit ProjectInserted(currId, teamId);
        currId += 1;
    }

    function updateTableDynamic(uint256 id, string[] memory columns, string[] memory values) external {
        require(columns.length == values.length, "Columns and values length mismatch");

        //Create key-value pairs for setters
        string memory setters = string.concat(columns[0], "=", SQLHelpers.quote(values[0]));

        for (uint256 i = 1; i < columns.length; i++) {
            setters = string.concat(setters, ",", columns[i], "=", SQLHelpers.quote(values[i]));
        }

        string memory filters = string.concat(
            "id=",
            Strings.toString(id),
            "teamId=",
            Strings.toString(idToTeamId[id])
        );

        TablelandDeployments.get().mutate(
            address(this),
            _tableId,
            SQLHelpers.toUpdate(_TABLE_PREFIX, _tableId, setters, filters)
        );
    }

    function updateTableCol(uint256 id, uint256 teamId, string memory colName, string memory val) external {
        require (Strings.equal(colName, "id") == false, "Cannot update id");
        require (Strings.equal(colName, "teamId") == false, "Cannot update teamId");
        if (msg.sender != owner()) {
            require(_moonDaoTeam.isManager(teamId, msg.sender), "Only Manager or Owner can update");
        }

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
        emit ProjectUpdated(id, teamId);
    }

    function deleteFromTable(uint256 id) external {
        if (msg.sender != owner()) {
            require(_moonDaoTeam.isManager(idToTeamId[id], msg.sender), "Only Manager or Owner can delete");
        }

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
        emit ProjectDeleted(id, idToTeamId[id]);
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
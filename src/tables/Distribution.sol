pragma solidity >=0.8.11 <0.9.0;

import "@evm-tableland/contracts/interfaces/ITablelandTables.sol";
import "@evm-tableland/contracts/interfaces/ITablelandController.sol";
import {TablelandController} from "@evm-tableland/contracts/TablelandController.sol";
import "@evm-tableland/contracts/utils/TablelandDeployments.sol";
import {SQLHelpers} from "@evm-tableland/contracts/utils/SQLHelpers.sol";
import {TablelandPolicy} from "@evm-tableland/contracts/TablelandPolicy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {MoonDAOCitizen} from "../ERC5643Citizen.sol";

//import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Distribution is TablelandController {
    using ERC165Checker for address;

    uint256 private _tableId;
    // address of citizen nft
    address private _citizenNft;
    string private _TABLE_PREFIX;
    string private constant DISTRIBUTIONS_SCHEMA =
        "id integer primary key, quarter integer, year integer, address text, distribution text, unique(quarter, year, address)";

    //constructor(address citizenNft) Ownable(msg.sender) {
    constructor(string memory _table_prefix)  {
        _TABLE_PREFIX = _table_prefix;
        //_citizenNft = citizenNft;
        // Create questions table.
        _tableId = TablelandDeployments.get().create(
            // TODO set to this contract eg. address(this)
            //address(msg.sender),
            address(this),
            SQLHelpers.toCreateFromSchema(DISTRIBUTIONS_SCHEMA, _TABLE_PREFIX)
        );

        // Set controller for distribution table to this contract.
        TablelandDeployments.get().setController(
            address(this),
            _tableId,
            address(this)
        );
    }

    // Create an distribution for a given quarter and year.
    // Here we let the contract do inserts into the distribution table.
    // The sender must be a holder of a citizen token to distribute.
    function insertIntoTable(uint256 quarter, uint256 year, string memory distribution) external {
        //require(
            //MoonDAOCitizen(_citizenNft).balanceOf(msg.sender) > 0,
            //"sender is not token owner"
        //);

        // Get the id of the citizen
        //uint256 citizenId = MoonDAOCitizen(_citizenNft).getOwnedToken(msg.sender);

        // Insert answer.
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
                    SQLHelpers.quote(distribution)
                )
            )
        );
    }

    // Set the ACL controller to enable row-level writes with dynamic policies
    //function setAccessControl(address controller) external onlyOwner{
        //TablelandDeployments.get().setController(
            //address(this), // Table owner, i.e., this contract
            //_tableId,
            //controller // Set the controller address—a separate controller contract
        //);
    //}

    // Implement ITablelandController for distribution table.
    // Anyone can insert.
    function getPolicy(address caller, uint256) public payable override returns (TablelandPolicy memory) {
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

    // Return the table ID
    function getTableId() external view returns (uint256) {
        return _tableId;
    }

    // Return the table name
    function getTableName() external view returns (string memory) {
        return SQLHelpers.toNameFromId(_TABLE_PREFIX, _tableId);
    }

}

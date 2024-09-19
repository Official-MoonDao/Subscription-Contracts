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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MoonDaoDelegation is TablelandController, Ownable {
    using ERC165Checker for address;

    uint256 private _delegationsTableId;
    // address of citizen nft
    address private _MOONEY_ADDRESS;
    string private constant DELEGATIONS_PREFIX = "citizen_delegations";
    string private constant DELEGATIONS_SCHEMA =
        "id integer primary key, quarter integer, year integer, address text, delegation text, unqiue(quarter, year, address)";

    constructor(address MOONEY_ADDRESS) Ownable(msg.sender){
        _MOONEY_ADDRESS = MOONEY_ADDRESS;
        // Create questions table.
        _delegationsTableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(DELEGATIONS_SCHEMA, DELEGATIONS_PREFIX)
        );

        // Set controller for questions table to this contract.
        TablelandDeployments.get().setController(
            address(this),
            _delegationsTableId,
            address(this)
        );
    }

    // Create an delegation for a given quarter and year.
    // Here we let the contract do inserts into the delegation table.
    // The sender must be a holder of a citizen token to distribute.
    function distribute(uint256 quarter, uint256 year, string memory delegation) external {
        // require mooney holder
        //require(
            ////ERC5643Citizen(token).balanceOf(msg.sender) > 0,
            ////"sender is not token owner"
        //);

        // Get the id of the citizen
        //uint256 citizenId = ERC5643Citizen(token).getOwnedToken(msg.sender);

        // Insert answer.
        TablelandDeployments.get().mutate(
            address(this),
            _delegationsTableId,
            SQLHelpers.toInsert(
                DELEGATIONS_PREFIX,
                _delegationsTableId,
                "quarter,year,citizen,address,delegation",
                string.concat(
                    Strings.toString(quarter),
                    ",",
                    Strings.toString(year),
                    ",",
                    Strings.toString(msg.sender),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(msg.sender)),
                    ",",
                    SQLHelpers.quote(delegation)
                )
            )
        );
    }

    // Implement ITablelandController for questions table.
    // Anyone can insert.
    // Nobody can update or delete.
    function getPolicy(address caller, uint256) public payable override returns (TablelandPolicy memory) {
        return
            TablelandPolicy({
                allowInsert: false,
                allowUpdate: false,
                allowDelete: false,
                whereClause: "",
                withCheck: "",
                updatableColumns: new string[](0)
            });
    }

    // Return the questions table name
    function getDelegationsTable() public view returns (string memory) {
        return SQLHelpers.toNameFromId(DELEGATIONS_PREFIX, _delegationsTableId);
    }
}

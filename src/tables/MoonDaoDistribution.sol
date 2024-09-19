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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MoonDaoDistribution is TablelandController, Ownable {
    using ERC165Checker for address;

    uint256 private _distributionsTableId;
    // address of citizen nft
    address private _citizenNft;
    string private constant DISTRIBUTIONS_PREFIX = "citizen_distributions";
    string private constant DISTRIBUTIONS_SCHEMA =
        "id integer primary key, quarter integer, year integer, citizen integer, address text, distribution text, unqiue(quarter, year, citizen)";

    constructor(address citizenNft) Ownable(msg.sender) {
        _citizenNft = citizenNft;
        // Create questions table.
        _distributionsTableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(DISTRIBUTIONS_SCHEMA, DISTRIBUTIONS_PREFIX)
        );

        // Set controller for questions table to this contract.
        TablelandDeployments.get().setController(
            address(this),
            _distributionsTableId,
            address(this)
        );
    }

    // Create an distribution for a given quarter and year.
    // Here we let the contract do inserts into the distribution table.
    // The sender must be a holder of a citizen token to distribute.
    function distribute(uint256 quarter, uint256 year, string memory distribution) external {
        require(
            MoonDAOCitizen(_citizenNft).balanceOf(msg.sender) > 0,
            "sender is not token owner"
        );

        // Get the id of the citizen
        uint256 citizenId = MoonDAOCitizen(_citizenNft).getOwnedToken(msg.sender);

        // Insert answer.
        TablelandDeployments.get().mutate(
            address(this),
            _distributionsTableId,
            SQLHelpers.toInsert(
                DISTRIBUTIONS_PREFIX,
                _distributionsTableId,
                "quarter,year,citizen,address,distribution",
                string.concat(
                    Strings.toString(quarter),
                    ",",
                    Strings.toString(year),
                    ",",
                    Strings.toString(citizenId),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(msg.sender)),
                    ",",
                    SQLHelpers.quote(distribution)
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
    function getDistributionsTable() public view returns (string memory) {
        return SQLHelpers.toNameFromId(DISTRIBUTIONS_PREFIX, _distributionsTableId);
    }
}

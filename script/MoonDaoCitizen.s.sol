// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
// import "../src/tables/MoonDaoTableland.sol";
import "../src/ERC5643Citizen.sol";
import {CitizenRowController} from "../src/tables/CitizenRowController.sol";
import {Whitelist} from "../src/Whitelist.sol";

contract MyScript is Script {
    function run() external {
        address TREASURY = 0xAF26a002d716508b7e375f1f620338442F5470c0;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Whitelist whitelist = new Whitelist();

        Whitelist discountList = new Whitelist();

        MoonDaoCitizenTableland citizenTable  = new MoonDaoCitizenTableland("CITIZENTABLE");

        MoonDAOCitizen citizen = new MoonDAOCitizen("MoonDaoCitizen", "MDC", TREASURY, address(citizenTable), address(whitelist), address(discountList));

        // citizen.setOpenAccess(true);

        CitizenRowController citizenRowController = new CitizenRowController(address(citizenTable));

        citizenRowController.addTableOwner(address(citizen));

        citizenTable.setAccessControl(address(citizenRowController));

        vm.stopBroadcast();
    }
}

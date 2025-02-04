// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


interface ICitizenContract {
    function mintTo(
        address to,
        string memory name,
        string memory bio,
        string memory image,
        string memory location,
        string memory discord,
        string memory twitter,
        string memory website,
        string memory _view,
        string memory formId
    ) external payable;
}


/**
Deploy on source and destination chain with appropriate lzEndpoint.
(https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts)

Then run script/CrossChainMinterConnect.s.sol on both chains with the appropriate source address,
destination address and destination endpoint id.
*/
contract CrossChainMinter is OApp {
    uint256 public constant MINT_PRICE = 0.0111 ether;

    address public citizenAddress;
    constructor(address _endpoint, address _citizenContract) OApp(_endpoint, msg.sender) Ownable(msg.sender) {
        citizenAddress = _citizenContract;
    }

    function crossChainMint(
        uint16 _dstEid,
        bytes calldata _options,
        address to,
        string memory name,
        string memory bio,
        string memory image,
        string memory location,
        string memory discord,
        string memory twitter,
        string memory website,
        string memory _view,
        string memory formId
    ) external payable {
        require(msg.value >= MINT_PRICE, "Insufficient payment");
        bytes memory payload = abi.encode(
            to,
            name,
            bio,
            image,
            location,
            discord,
            twitter,
            website,
            _view,
            formId
        );

        _lzSend(
            _dstEid,        // destination chainId
            payload,            // bytes payload
            _options,           // bytes options
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address,  // Executor address as specified by the OApp.
        bytes calldata  // Any extra data or options to trigger on receipt.
    ) internal override {
        (
            address to,
            string memory name,
            string memory bio,
            string memory image,
            string memory location,
            string memory discord,
            string memory twitter,
            string memory website,
            string memory _view,
            string memory formId
        ) = abi.decode(
            payload,
            (address, string, string, string, string, string, string, string, string, string)
        );

        ICitizenContract(citizenAddress).mintTo{value: 0.0111 ether}(
            to,
            name,
            bio,
            image,
            location,
            discord,
            twitter,
            website,
            _view,
            formId
        );
    }
}

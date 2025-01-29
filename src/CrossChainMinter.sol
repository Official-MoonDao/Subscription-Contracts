// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ---------------------------------------------------------------------------
// Import LayerZero core + Nonblocking app
// (Adjust the import paths to match your setup)
// ---------------------------------------------------------------------------
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

contract CrossChainMinter is NonblockingLzApp {
    // The price to mint an NFT (example: 0.01 ETH).
    //uint256 public constant MINT_PRICE = 0.01 ether;

    // -----------------------------------------------------------------------
    // Constructor - requires the LayerZero endpoint for the Base network
    // (You must use the correct endpoint address for Base)
    // -----------------------------------------------------------------------
    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    /**
     * @notice This function takes payment, then sends the mint details
     *         cross-chain to Arbitrum via LayerZero.
     *
     * @param _dstChainId LayerZero chain ID for Arbitrum
     * @param to address to receive the NFT on Arbitrum
     * @param name NFT metadata parameter
     * @param bio NFT metadata parameter
     * @param image NFT metadata parameter
     * @param location NFT metadata parameter
     * @param discord NFT metadata parameter
     * @param twitter NFT metadata parameter
     * @param website NFT metadata parameter
     * @param _view NFT metadata parameter
     * @param formId NFT metadata parameter
     */
    function crossChainMint(
        uint16 _dstChainId,
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
        // 1. Collect payment
        //require(msg.value >= MINT_PRICE, "Insufficient payment");

        // (Optionally, handle any payment distribution or refunds if msg.value > MINT_PRICE)

        // 2. Encode the mint data into payload
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

        // 3. Send the payload cross-chain
        //    The adapterParams can be customized to pay for extra gas on the destination chain
        //    (for bigger mint logic). Here, we pass empty bytes for simplicity.
        _lzSend(
            _dstChainId,        // destination chainId
            payload,            // bytes payload
            payable(msg.sender),// refund address (unused if no extra gas)
            address(0),         // future usage (zroPaymentAddress), set to address(0)
            bytes("")           // adapterParams (extra gas instructions)
        );
    }

    /**
     * @notice This is required by NonblockingLzApp but we don’t need
     *         to receive any cross-chain messages on the Base chain.
     */
    function _nonblockingLzReceive(
        uint16, /*_srcChainId*/
        bytes memory, /*_srcAddress*/
        uint64, /*_nonce*/
        bytes memory /*_payload*/
    ) internal override {
         // 1. Decode the payload into the parameters we need to pass to mintTo(...)
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
            _payload,
            (address, string, string, string, string, string, string, string, string, string)
        );

        // 2. Call the target NFT contract on Arbitrum
        IDestinationNFT(NFT_CONTRACT).mintTo(
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

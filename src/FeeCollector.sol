// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';



contract FeeSender {
    using OptionsBuilder for bytes;

    ILayerZeroEndpoint public endpoint;
    // The destination aggregator contract on Mainnet (target chain)
    bytes public aggregatorAddress;
    // Destination chain id for Mainnet in LayerZero’s system
    uint16 public constant MAINNET_CHAIN_ID = 101;
    // v4
    //0x000000000004444c5dc75cB358380D2e3dE08A90 mainnet
    //0x360e68faccca8ca495c1b759fd9eee466db9fb32 arbitrum one
    //0x498581ff718922c3f8e6a244956af099b2652b2b base
    IPositionManager positionManager;
    // v3
    //0xC36442b4a4522E871399CD717aBDD847Ab11FE88 mainnet
    //0xC36442b4a4522E871399CD717aBDD847Ab11FE88 arbitrum one
    //0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1 base
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    IWETH9 public immutable weth9;
    uint256 v3TokenIds[];
    uint256 v4TokenIds[];
    address v4TokenAddresses[];




    constructor(address _endpoint, bytes memory _aggregatorAddress, address _v4PosmAddress, address _v3PosmAddress, address _weth9Address) {
        endpoint = ILayerZeroEndpoint(_endpoint);
        aggregatorAddress = _aggregatorAddress;
        positionManager = IPositionManager(_v4PosmAddress);
        nonfungiblePositionManager = INonfungiblePositionManager(_v3PosmAddress);
        weth9 = IWETH9(_weth9Address);
    }

    function addV3Token(uint256 tokenId) external {
        v3TokenIds.push(tokenId);
    }

    function addV4TokenId(uint256 tokenId, address _address) external {
        v4TokenIds.push(tokenId);
        v4TokenAddresses.push(_address);
    }

    // Call this function when you want to send fees to Mainnet aggregator
    function sendFees(uint16 _dstEid) external payable {
        for (uint256 i = 0; i < v3TokenIds.length; i++) {
            collectFeesV3(v3TokenIds[i]);
        }
        for (uint256 i = 0; i < v4TokenIds.length; i++) {
            collectFeesV4(v4TokenIds[i], address(this), address(0), v4TokenAddresses[i]));
        }
        if (weth9.balanceOf(address(this)) > 0) {
            weth9.withdraw(weth9.balanceOf(address(this)));
        }
        // Prepare payload
        bytes memory payload = abi.encode();
        // Fee for messaging (assumed to be provided)
        uint256 messageFee = msg.value;
        uint256 totalAmount = address(this).balance;
        uint256 GAS_LIMIT = 500000;
        uint256 VALUE = this.balance;
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, VALUE);

        _lzSend(
            _dstEid,        // destination chainId
            payload,            // bytes payload
            options,           // bytes options
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
    }

    /**
     * @notice Collects all fees from the provided Uniswap v3 liquidity position NFT and returns it.
     * @dev The NFT is temporarily transferred to this contract to enable fee collection.
     * @param tokenId The NFT's token ID.
     * @return amount0 The fees collected in token0.
     * @return amount1 The fees collected in token1.
     */
    function collectFeesV3(uint256 tokenId) internal returns (uint256 amount0, uint256 amount1) {
        nonfungiblePositionManager.safeTransferFrom(msg.sender, address(this), tokenId);

        originalOwner[tokenId] = msg.sender;

        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        _sendToOwner(tokenId, amount0, amount1);

        nonfungiblePositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /// @notice Collects accumulated fees from a position
    /// @param tokenId The ID of the position to collect fees from
    /// @param recipient Address that will receive the fees
    function collectFeesV4(
        uint256 tokenId,
        address recipient,
        address tokenAddress1,
        address tokenAddress2
    ) internal {
        // Define the sequence of operations
        bytes memory actions = abi.encodePacked(
            Actions.DECREASE_LIQUIDITY, // Remove liquidity
            Actions.TAKE_PAIR           // Receive both tokens
        );

        // Prepare parameters array
        bytes[] memory params = new bytes[](2);

        // Parameters for DECREASE_LIQUIDITY
        // All zeros since we're only collecting fees
        params[0] = abi.encode(
            tokenId,    // Position to collect from
            0,          // No liquidity change
            0,          // No minimum for token0 (fees can't be manipulated)
            0,          // No minimum for token1
            ""          // No hook data needed
        );
        Currency currency0 = Currency.wrap(tokenAddress1); // tokenAddress1 = 0 for native ETH
        Currency currency1 = Currency.wrap(tokenAddress2);
        // Standard TAKE_PAIR for receiving all fees
        params[1] = abi.encode(
            currency0,
            currency1,
            recipient
        );
        // Execute fee collection
        positionManager.modifyLiquidities(
            abi.encode(actions, params),
            block.timestamp + 60  // 60 second deadline
        );
    }

    // Allow contract to receive ETH (if needed)
    receive() external payable {}

    // Allow our contract to accept NFTs for LP positions
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

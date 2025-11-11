// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

interface ICustodian {
    struct Trade {
        //might want to execute identical trades, would not be possible without nonce to change hash
        //so it is not blocked by anti replay protection
        //no invariants for nonce, can reuse nonce however
        //only used to allow for identical transactions in all other aspects
        uint256 nonce;
        //trade parties
        address maker;
        address taker;
        //Trade info
        IERC20 makerAsset;
        uint256 makerAssetAmount;
        IERC20 takerAsset;
        uint256 takerAssetAmount;
        //time limits
        uint256 expiryTime;
        //block number limits
        uint256 expiryBlock;
    }

    struct SignedTrade {
        bytes makerSig;
        bytes takerSig;
        Trade trade;
    }

    /// @notice Execute a trade signed offchain
    /// @param signedTrade Signed trade to execute
    function executeTrade(SignedTrade memory signedTrade) external;
}

contract Custodian is EIP712, ICustodian {
    using SafeERC20 for IERC20;

    //need to avoid signature malleability attacks too
    //to avoid replay attacks
    mapping(bytes32 => bool) public filledTrades;

    error TradeExpiredBlock();

    error TradeExpiredTime();

    error TradeAlreadyExecuted();

    error TradeMakerSignatureInvalid();

    error TradeTakerSignatureInvalid();

    bytes32 public constant TRADE_TYPEHASH = keccak256(
        abi.encodePacked(
            "Trade(",
            "uint256 nonce,",
            "address maker,",
            "address taker,",
            "address makerAsset,",
            "uint256 makerAssetAmount,",
            "IERC20 takerAsset,",
            "uint256 takerAssetAmount,",
            "uint256 expiryTime,",
            "uint256 expiryBlock",
            ")"
        )
    );

    constructor() EIP712("Custodian", "v1") {}

    function getTradeEIP712Hash(Trade memory trade) external view returns (bytes32 hash) {
        hash = _getTradeEIP712Hash(trade);
    }

    function _getTradeHash(Trade memory trade) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                TRADE_TYPEHASH,
                trade.nonce,
                trade.maker,
                trade.taker,
                trade.makerAsset,
                trade.makerAssetAmount,
                trade.takerAsset,
                trade.takerAssetAmount,
                trade.expiryTime,
                trade.expiryBlock
            )
        );
    }

    //Need salt to avoid mixing domains between different sigs
    //ex. chainid
    //eip712 solves this?
    //using https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol
    //https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct
    //tokenlon view-source:https://etherscan.io/address/0x4a14347083B80E5216cA31350a2D21702aC3650d#code
    //https://medium.com/metamask/eip712-is-coming-what-to-expect-and-how-to-use-it-bb92fd1a7a26
    //https://github.com/msfeldstein/EIP712-whitelisting/blob/main/contracts/EIP712Whitelisting.sol

    function _getTradeEIP712Hash(Trade memory trade) internal view returns (bytes32) {
        bytes32 hash = _getTradeHash(trade);
        bytes32 digest = _hashTypedDataV4(hash);
        return digest;
    }

    //use calldata for Trade instead of memory? best praxis?
    function executeTrade(SignedTrade memory signedTrade) external {
        bytes32 tradeHash = _getTradeEIP712Hash(signedTrade.trade);
        Trade memory trade = signedTrade.trade;

        //check if Trade previously executed (Replay protection)
        require(filledTrades[tradeHash] == false, TradeAlreadyExecuted());
        filledTrades[tradeHash] = true;

        //check expiration time of trade
        require(trade.expiryTime >= block.timestamp, TradeExpiredTime());

        //check expiration block of trade
        require(trade.expiryBlock >= block.number, TradeExpiredBlock());

        //verify signatures of trade
        address makerRecoveredAddress = ECDSA.recover(tradeHash, signedTrade.makerSig);
        address takerRecoveredAddress = ECDSA.recover(tradeHash, signedTrade.takerSig);

        require(makerRecoveredAddress == trade.maker, TradeMakerSignatureInvalid());
        require(takerRecoveredAddress == trade.taker, TradeTakerSignatureInvalid());

        //execute trade
        trade.makerAsset.safeTransferFrom(trade.maker, trade.taker, trade.makerAssetAmount);
        trade.takerAsset.safeTransferFrom(trade.taker, trade.maker, trade.takerAssetAmount);
    }
}

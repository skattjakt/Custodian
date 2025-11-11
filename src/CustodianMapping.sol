// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICustodian {
    /// @notice Cancel a previously created offer
    /// @notice Only creator of offer can cancel it
    /// @param offerID ID of offer
    function cancelOffer(uint256 offerID) external;

    /// @notice Create a new offer
    /// @param taker Recipient of offer
    /// @param makerAsset Address of asset being sold by maker
    /// @param makerAssetAmount Amount of asset being sold by maker
    /// @param takerAsset Address of asset being bought by maker
    /// @param takerAssetAmount Amount of asset being bought by maker
    /// @param expiryTime Deadline for offer to be accepted before it expires
    /// @return ID The ID of the created offer
    function createOffer(
        address taker,
        IERC20 makerAsset,
        uint256 makerAssetAmount,
        IERC20 takerAsset,
        uint256 takerAssetAmount,
        uint256 expiryTime
    ) external returns (uint256 ID);

    /// @notice Execute and fill an offer
    /// @param offerID ID of offer
    function fillOffer(uint256 offerID) external;
}

/// @title Custodian main contract
contract Custodian is ICustodian {
    using SafeERC20 for IERC20;

    struct Offer {
        bool active;
        //trade parties
        address taker;
        address maker;
        //offer info
        IERC20 makerAsset;
        uint256 makerAssetAmount;
        IERC20 takerAsset;
        uint256 takerAssetAmount;
        //time limits
        uint256 expiryTime;
    }

    mapping(uint256 => Offer) public offers;
    uint256 public OfferIDNonce;

    uint256 public currentID;
    address public admin;

    /// @notice Emitted when a new offer has been created
    /// @param _maker Create of the offer
    /// @param _taker Recipient of offer
    /// @param ID ID of offer
    /// @param makerAsset Address of asset being sold by maker
    /// @param makerAssetAmount Amount of asset being sold by maker
    /// @param takerAsset Address of asset being bought by maker
    /// @param takerAssetAmount Amount of asset being bought by maker
    /// @param expiryTime Deadline for offer to be accepted before it expires
    event offerCreated(
        address indexed _maker,
        address indexed _taker,
        uint256 indexed ID,
        IERC20 makerAsset,
        uint256 makerAssetAmount,
        IERC20 takerAsset,
        uint256 takerAssetAmount,
        uint256 expiryTime
    );

    /// @notice Emitted when a new offer is filled
    /// @param _maker Create of the offer
    /// @param _taker Recipient of offer
    /// @param ID ID of offer
    /// @param makerAsset Address of asset being sold by maker
    /// @param makerAssetAmount Amount of asset being sold by maker
    /// @param takerAsset Address of asset being bought by maker
    /// @param takerAssetAmount Amount of asset being bought by maker
    event offerFilled(
        address indexed _maker,
        address indexed _taker,
        uint256 indexed ID,
        IERC20 makerAsset,
        uint256 makerAssetAmount,
        IERC20 takerAsset,
        uint256 takerAssetAmount
    );

    /// @dev Only the maker can cancel an offer
    error Unauthorized();

    /// @dev Only the taker in an offer can accept it
    error OfferOnlyTakerCanAccept();

    /// @dev The offer is no longer active
    error OfferNotActive();

    /// @dev The offer has expired
    error OfferExpiredDeadline();

    constructor() {}

    /// @inheritdoc ICustodian
    function cancelOffer(uint256 id) external {
        Offer storage offer = offers[id];
        require(offer.maker == msg.sender, Unauthorized());
        _cancelOffer(id);
    }

    function _cancelOffer(uint256 id) internal {
        delete offers[id];
    }

    /// @inheritdoc ICustodian
    function createOffer(
        address taker,
        IERC20 makerAsset,
        uint256 makerAssetAmount,
        IERC20 takerAsset,
        uint256 takerAssetAmount,
        uint256 expiryTime
    ) external returns (uint256) {
        Offer memory offer = Offer({
            active: true,
            taker: taker,
            maker: msg.sender,
            makerAsset: makerAsset,
            makerAssetAmount: makerAssetAmount,
            takerAsset: takerAsset,
            takerAssetAmount: takerAssetAmount,
            expiryTime: expiryTime
        });

        OfferIDNonce += 1;
        offers[OfferIDNonce] = offer;

        emit offerCreated(
            offer.taker,
            offer.maker,
            OfferIDNonce,
            offer.makerAsset,
            offer.makerAssetAmount,
            offer.takerAsset,
            offer.takerAssetAmount,
            offer.expiryTime
        );

        return OfferIDNonce;
    }

    /// @inheritdoc ICustodian
    function fillOffer(uint256 offerID) external {
        Offer memory offer = offers[offerID];

        require(offer.active == true, OfferNotActive());
        require(offer.expiryTime >= block.timestamp, OfferExpiredDeadline());
        require(offer.taker == msg.sender, OfferOnlyTakerCanAccept());

        _cancelOffer(offerID);
        offer.makerAsset.safeTransferFrom(offer.maker, offer.taker, offer.makerAssetAmount);
        offer.takerAsset.safeTransferFrom(offer.taker, offer.maker, offer.takerAssetAmount);

        emit offerFilled(
            offer.taker,
            offer.maker,
            offerID,
            offer.makerAsset,
            offer.makerAssetAmount,
            offer.takerAsset,
            offer.takerAssetAmount
        );
    }
}

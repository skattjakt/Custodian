// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Custodian, ICustodian} from "../src/CustodianStateless.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
}

contract CustodianTest is Test {
    Custodian public custodian;
    address public addr1;
    uint256 public addr1PrivateKey;
    address public addr2;
    uint256 public addr2PrivateKey;
    IERC20 public token1;
    IERC20 public token2;

    function setUp() public {
        custodian = new Custodian();
        addr1PrivateKey = 1;
        addr1 = vm.addr(addr1PrivateKey);

        addr2PrivateKey = 2;
        addr2 = vm.addr(addr2PrivateKey);

        token1 = new Token("token1", "tk1");
        token2 = new Token("token2", "tk2");
    }

    function signHash(uint256 privateKey, bytes32 hash) internal returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        signature = abi.encodePacked(r, s, v);
    }

    function test_ExecuteTrade() public {
        uint256 makerAssetAmount = 1 ether;
        uint256 takerAssetAmount = 1 ether;

        vm.startPrank(addr1);

        ICustodian.Trade memory trade = ICustodian.Trade({
            nonce: 0,
            maker: addr1,
            makerAsset: token1,
            makerAssetAmount: makerAssetAmount,
            taker: addr2,
            takerAsset: token2,
            takerAssetAmount: takerAssetAmount,
            expiryTime: block.timestamp + 1,
            expiryBlock: block.number
        });

        bytes32 hash = custodian.getTradeEIP712Hash(trade);

        bytes memory makerSig = signHash(addr1PrivateKey, hash);
        bytes memory takerSig = signHash(addr2PrivateKey, hash);

        ICustodian.SignedTrade memory signedTrade =
            ICustodian.SignedTrade({makerSig: makerSig, takerSig: takerSig, trade: trade});

        deal(address(token1), addr1, makerAssetAmount);
        deal(address(token2), addr2, takerAssetAmount);
        assertEq(token1.balanceOf(addr1), makerAssetAmount);
        assertEq(token2.balanceOf(addr2), takerAssetAmount);

        token1.approve(address(custodian), type(uint256).max);
        vm.startPrank(addr2);
        token2.approve(address(custodian), type(uint256).max);

        custodian.executeTrade(signedTrade);
    }
}

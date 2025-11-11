// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Custodian} from "../src/Custodian.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
}

contract CustodianTest is Test {
    Custodian public custodian;
    address public addr1;
    address public addr2;
    IERC20 public token1;
    IERC20 public token2;

    function setUp() public {
        custodian = new Custodian();
        addr1 = vm.addr(1);
        addr2 = vm.addr(2);
        token1 = new Token("token1", "tk1");
        token2 = new Token("token2", "tk2");
    }

    function test_CreateOffer() public {
        custodian.createOffer(addr1, token1, 1 ether, token2, 10 ether, block.timestamp + 100);
    }

    function test_CreateAndFillOffer() public {
        uint256 makerAssetAmount = 1 ether;
        uint256 takerAssetAmount = 10 ether;
        uint256 deadline = block.timestamp + 1;

        uint256 offerID = custodian.createOffer(addr1, token1, makerAssetAmount, token2, takerAssetAmount, deadline);

        deal(address(token1), address(this), makerAssetAmount);
        deal(address(token2), addr1, takerAssetAmount);
        assertEq(token1.balanceOf(address(this)), makerAssetAmount);
        assertEq(token2.balanceOf(addr1), takerAssetAmount);

        token1.approve(address(custodian), type(uint256).max);
        vm.startPrank(addr1);
        token2.approve(address(custodian), type(uint256).max);
        custodian.fillOffer(offerID);

        assertEq(token2.balanceOf(address(this)), takerAssetAmount);
        assertEq(token1.balanceOf(addr1), makerAssetAmount);
    }

    function test_PastDeadlineReverts() public {
        vm.warp(1000);
        uint256 deadline = block.timestamp - 1;

        uint256 makerAssetAmount = 1 ether;
        uint256 takerAssetAmount = 10 ether;
        uint256 offerID = custodian.createOffer(addr1, token1, makerAssetAmount, token2, takerAssetAmount, deadline);

        vm.expectRevert(Custodian.OfferExpiredDeadline.selector);
        custodian.fillOffer(offerID);
    }

    function test_MultipleOffers() public {
        uint256 deadline = block.timestamp + 1;

        uint256 makerAssetAmount = 1 ether;
        uint256 takerAssetAmount = 10 ether;
        custodian.createOffer(addr1, token1, makerAssetAmount, token2, takerAssetAmount, deadline);
        custodian.createOffer(addr1, token1, makerAssetAmount, token2, takerAssetAmount, deadline);
        custodian.createOffer(addr1, token1, makerAssetAmount, token2, takerAssetAmount, deadline);
        custodian.createOffer(addr1, token1, makerAssetAmount, token2, takerAssetAmount, deadline);
    }

    function test_CreateAndCancelOffer() public {
        uint256 makerAssetAmount = 1 ether;
        uint256 takerAssetAmount = 10 ether;
        uint256 deadline = block.timestamp + 1;

        uint256 offerID = custodian.createOffer(addr1, token1, makerAssetAmount, token2, takerAssetAmount, deadline);
        custodian.cancelOffer(offerID);
        vm.startPrank(addr1);
        vm.expectRevert(Custodian.OfferNotActive.selector);
        custodian.fillOffer(offerID);
    }

    function test_OnlyTakerCanAcceptOffer() public {
        uint256 offerID = custodian.createOffer(addr1, token1, 1 ether, token2, 1 ether, block.timestamp + 1);
        vm.startPrank(addr2);
        vm.expectRevert(Custodian.OfferOnlyTakerCanAccept.selector);
        custodian.fillOffer(offerID);
    }

    function test_OnlyMakerCanCancelOffer() public {
        uint256 offerID = custodian.createOffer(addr1, token1, 1 ether, token2, 1 ether, block.timestamp + 1);
        vm.startPrank(addr1);
        vm.expectRevert(Custodian.Unauthorized.selector);
        custodian.cancelOffer(offerID);
    }

    function test_FillOfferTwice() public {
        uint256 makerAssetAmount = 1 ether;
        uint256 takerAssetAmount = 10 ether;
        uint256 deadline = block.timestamp + 1;

        uint256 offerID = custodian.createOffer(addr1, token1, makerAssetAmount, token2, takerAssetAmount, deadline);

        deal(address(token1), address(this), makerAssetAmount);
        deal(address(token2), addr1, takerAssetAmount);
        token1.approve(address(custodian), type(uint256).max);
        vm.startPrank(addr1);
        token2.approve(address(custodian), type(uint256).max);
        custodian.fillOffer(offerID);

        vm.expectRevert(Custodian.OfferNotActive.selector);
        custodian.fillOffer(offerID);
    }
}

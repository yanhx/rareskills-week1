// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithSactions} from "../../TokenWithSactions.sol";
import {DeployTokenWithSactions} from "../../../script/DeployTokenWithSactions.s.sol";

contract TokenWithSactionsTest is Test {
    TokenWithSactions tokenWithSactions;
    address USER = makeAddr("user");

    uint256 constant TRANSFER_AMOUNT = 0.1 ether;

    function setUp() external {
        DeployTokenWithSactions deployTokenWithSactions = new DeployTokenWithSactions();
        tokenWithSactions = deployTokenWithSactions.run();
        vm.deal(USER, 10 ether);
    }

    /**
     * fund USER account with ETH
     */
    modifier fundedWithToken() {
        vm.prank(msg.sender);
        tokenWithSactions.transfer(USER, TRANSFER_AMOUNT);
        _;
    }

    /**
     * test transfer from wallet that is not blacklisted
     */
    function testNonBlacklistedTransfer() public fundedWithToken {
        vm.prank(USER);
        tokenWithSactions.transfer(address(uint160(2)), TRANSFER_AMOUNT);

        uint256 endingUserBalance = tokenWithSactions.balanceOf(USER);
        uint256 endingReceiverBalance = tokenWithSactions.balanceOf(
            address(uint160(2))
        );
        assertEq(endingUserBalance, 0);
        assertEq(endingReceiverBalance, TRANSFER_AMOUNT);
    }

    /**
     * test transfer from wallet that is blacklisted
     */
    function testBlacklistedTransfer() public fundedWithToken {
        vm.prank(msg.sender);
        tokenWithSactions.blacklist(USER, true);
        vm.prank(USER);
        vm.expectRevert("Blacklisted");
        tokenWithSactions.transfer(address(uint160(2)), TRANSFER_AMOUNT);
    }

    /**
     * test transfer to wallet that is blacklisted
     */
    function testBlacklistedReceive() public {
        vm.prank(msg.sender);
        tokenWithSactions.blacklist(USER, true);
        vm.prank(msg.sender);
        vm.expectRevert("Blacklisted");
        tokenWithSactions.transfer(USER, TRANSFER_AMOUNT);
    }
}

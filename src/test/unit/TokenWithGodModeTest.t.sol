// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithGodMode} from "../../TokenWithGodMode.sol";
import {DeployTokenWithGodMode} from "../../../script/DeployTokenWithGodMode.s.sol";
import {IERC20Errors} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenWithGodModeTest is Test {
    TokenWithGodMode tokenWithGodMode;
    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");

    uint256 constant TRANSFER_AMOUNT = 0.1 ether;

    function setUp() external {
        DeployTokenWithGodMode deployTokenWithGodMode = new DeployTokenWithGodMode();
        tokenWithGodMode = deployTokenWithGodMode.run();
        vm.deal(USER1, 10 ether);
        vm.deal(USER2, 10 ether);
    }

    /**
     * fund wallets with Token
     */
    modifier fundedWithToken() {
        vm.prank(msg.sender);
        tokenWithGodMode.transfer(USER1, TRANSFER_AMOUNT);
        vm.prank(msg.sender);
        tokenWithGodMode.transfer(USER2, TRANSFER_AMOUNT);
        _;
    }

    /**
     * test transfer between normal wallets
     */
    function testTransferFrom1To2() public fundedWithToken {
        uint256 startingUser1Balance = tokenWithGodMode.balanceOf(USER1);
        uint256 startingUser2Balance = tokenWithGodMode.balanceOf(USER2);
        assertEq(startingUser1Balance, TRANSFER_AMOUNT);
        assertEq(startingUser2Balance, TRANSFER_AMOUNT);

        vm.prank(USER1);
        tokenWithGodMode.approve(USER2, TRANSFER_AMOUNT);
        vm.prank(USER2);
        tokenWithGodMode.transferFrom(USER1, USER2, TRANSFER_AMOUNT);

        uint256 endingUser1Balance = tokenWithGodMode.balanceOf(USER1);
        uint256 endingUser2Balance = tokenWithGodMode.balanceOf(USER2);

        assertEq(endingUser1Balance, 0);
        assertEq(endingUser2Balance, TRANSFER_AMOUNT * 2);
    }

    /**
     * test transfer between normal wallets without setting allowance
     */
    function testTransferFrom1To2WithoutAllowance() public fundedWithToken {
        uint256 startingUser1Balance = tokenWithGodMode.balanceOf(USER1);
        uint256 startingUser2Balance = tokenWithGodMode.balanceOf(USER2);
        assertEq(startingUser1Balance, TRANSFER_AMOUNT);
        assertEq(startingUser2Balance, TRANSFER_AMOUNT);

        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                USER2,
                0,
                TRANSFER_AMOUNT
            )
        );
        tokenWithGodMode.transferFrom(USER1, USER2, TRANSFER_AMOUNT);

        uint256 endingUser1Balance = tokenWithGodMode.balanceOf(USER1);
        uint256 endingUser2Balance = tokenWithGodMode.balanceOf(USER2);

        assertEq(endingUser1Balance, TRANSFER_AMOUNT);
        assertEq(endingUser2Balance, TRANSFER_AMOUNT);
    }

    /**
     * test transfer between normal wallets but initiated by God wallet.
     */
    function testTransferFrom1To2ByGod() public fundedWithToken {
        uint256 startingUser1Balance = tokenWithGodMode.balanceOf(USER1);
        uint256 startingUser2Balance = tokenWithGodMode.balanceOf(USER2);
        assertEq(startingUser1Balance, TRANSFER_AMOUNT);
        assertEq(startingUser2Balance, TRANSFER_AMOUNT);

        vm.prank(msg.sender);
        tokenWithGodMode.transferFrom(USER1, USER2, TRANSFER_AMOUNT);

        uint256 endingUser1Balance = tokenWithGodMode.balanceOf(USER1);
        uint256 endingUser2Balance = tokenWithGodMode.balanceOf(USER2);

        assertEq(endingUser1Balance, 0);
        assertEq(endingUser2Balance, TRANSFER_AMOUNT * 2);
    }
}

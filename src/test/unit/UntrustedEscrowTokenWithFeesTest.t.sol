// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {UntrustedEscrow} from "../../UntrustedEscrow.sol";
import {DeployUntrustedEscrow} from "../../../script/DeployUntrustedEscrow.s.sol";
import {MockERC20WithFees} from "../mocks/MockERC20WithFees.sol";

contract UntrustedEscrowTokenWithFeesTest is Test {
    UntrustedEscrow untrustedEscrow;
    address BUYER = makeAddr("buyer");
    address SELLER = makeAddr("seller");
    MockERC20WithFees mockERC20;

    uint256 private constant INITIAL_FUNDED = 10 ether;

    function setUp() external {
        DeployUntrustedEscrow deployUntrustedEscrow = new DeployUntrustedEscrow();
        untrustedEscrow = deployUntrustedEscrow.run();
        vm.deal(BUYER, 10 ether);
        vm.deal(SELLER, 10 ether);
        mockERC20 = new MockERC20WithFees();
    }

    modifier fundedBuyer() {
        mockERC20.mint(BUYER, INITIAL_FUNDED);
        _;
    }

    function testUpdateLockTime() public {
        vm.prank(BUYER);
        vm.expectRevert();
        untrustedEscrow.updateLockTime(5);

        vm.prank(msg.sender);
        untrustedEscrow.updateLockTime(5);
        assertEq(untrustedEscrow.LOCK_TIME(), 5 days);
    }

    function testDepositFails() public {
        vm.prank(BUYER);
        vm.expectRevert("Seller address cannot be zero");
        untrustedEscrow.deposit(address(0), address(mockERC20), 1000);

        vm.prank(BUYER);
        vm.expectRevert("Amount must be greater than zero");
        untrustedEscrow.deposit(SELLER, address(mockERC20), 0);

        vm.prank(BUYER);
        vm.expectRevert("Amount must be less than or equal to balance");
        untrustedEscrow.deposit(SELLER, address(mockERC20), 1);
    }

    function testDeposit() public fundedBuyer {
        vm.startPrank(BUYER);
        mockERC20.approve(address(untrustedEscrow), INITIAL_FUNDED);
        bytes32 escrowId = untrustedEscrow.deposit(
            SELLER,
            address(mockERC20),
            INITIAL_FUNDED
        );
        vm.stopPrank();

        assertEq(untrustedEscrow.getEscrowDetails(escrowId).buyer, BUYER);
        assertEq(untrustedEscrow.getEscrowDetails(escrowId).seller, SELLER);
        assertEq(
            untrustedEscrow.getEscrowDetails(escrowId).token,
            address(mockERC20)
        );
        assertEq(
            untrustedEscrow.getEscrowDetails(escrowId).amount,
            INITIAL_FUNDED
        );
        assertEq(
            untrustedEscrow.getEscrowDetails(escrowId).releaseTime,
            block.timestamp + 3 days
        );
        assertEq(untrustedEscrow.getEscrowDetails(escrowId).isActive, true);
        assertEq(mockERC20.balanceOf(address(untrustedEscrow)), INITIAL_FUNDED);
    }

    function testWithdrawFails() public fundedBuyer {
        vm.startPrank(BUYER);
        mockERC20.approve(address(untrustedEscrow), INITIAL_FUNDED);
        bytes32 escrowId = untrustedEscrow.deposit(
            SELLER,
            address(mockERC20),
            INITIAL_FUNDED
        );
        vm.stopPrank();

        vm.startPrank(SELLER);
        vm.expectRevert("Escrow is no longer active");
        untrustedEscrow.withdraw("");

        vm.expectRevert("Escrow is not yet released");
        untrustedEscrow.withdraw(escrowId);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 days);

        vm.startPrank(BUYER);
        vm.expectRevert("Only seller can withdraw");
        untrustedEscrow.withdraw(escrowId);
        vm.stopPrank();

        vm.startPrank(SELLER);
        untrustedEscrow.withdraw(escrowId);
        vm.expectRevert("Escrow is no longer active");
        untrustedEscrow.withdraw(escrowId);
        vm.stopPrank();
    }
}

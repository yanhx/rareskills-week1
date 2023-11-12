// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurveToken} from "../../BondingCurveToken.sol";
import {DeployBondingCurveToken} from "../../../script/DeployBondingCurveToken.s.sol";

contract BondingCurveTokenTest is Test {
    BondingCurveToken bondingCurveToken;
    address USER = makeAddr("user");

    uint256 private constant INITIAL_SUPPLY = 2 ether;
    uint256 private constant INITIAL_RESERVE_BALANCE = 2 ether;
    uint256 private constant INITIAL_FUNDED = 10 ether;
    uint256 private constant TRADE_AMOUNT = 1 ether;

    function setUp() external {
        DeployBondingCurveToken deployBondingCurveToken = new DeployBondingCurveToken();
        bondingCurveToken = deployBondingCurveToken.run(
            INITIAL_SUPPLY,
            INITIAL_RESERVE_BALANCE
        );
        vm.deal(USER, INITIAL_FUNDED);
    }

    // Helper function to calculate square root
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function testMintToken() public {
        uint256 tokenSupplyBefore = bondingCurveToken.totalSupply();
        uint256 tokenReserveBalanceBefore = bondingCurveToken.reserveBalance();
        uint256 tokenBuyerBalanceBefore = bondingCurveToken.balanceOf(USER);
        uint256 ethBuyerAmountBefore = USER.balance;

        assertEq(tokenSupplyBefore, INITIAL_SUPPLY);
        assertEq(tokenReserveBalanceBefore, INITIAL_RESERVE_BALANCE);
        assertEq(tokenBuyerBalanceBefore, 0);
        assertEq(ethBuyerAmountBefore, INITIAL_FUNDED);

        vm.prank(USER);
        bondingCurveToken.mint{value: TRADE_AMOUNT}();

        uint256 tokenSupplyAfter = bondingCurveToken.totalSupply();
        uint256 tokenReserveBalanceAfter = bondingCurveToken.reserveBalance();
        uint256 tokenBuyerBalanceAfter = bondingCurveToken.balanceOf(USER);
        uint256 ethBuyerAmountAfter = USER.balance;

        uint256 expectedTokenSupplyAfterSq = (TRADE_AMOUNT *
            INITIAL_SUPPLY *
            INITIAL_SUPPLY) /
            INITIAL_RESERVE_BALANCE +
            INITIAL_SUPPLY *
            INITIAL_SUPPLY;
        uint256 expectedTokenSupplyAfter = sqrt(expectedTokenSupplyAfterSq);

        assertApproxEqAbs(tokenSupplyAfter, expectedTokenSupplyAfter, 1);
        assertEq(
            tokenReserveBalanceAfter,
            INITIAL_RESERVE_BALANCE + TRADE_AMOUNT
        );
        assertApproxEqAbs(
            tokenBuyerBalanceAfter,
            expectedTokenSupplyAfter - INITIAL_SUPPLY,
            1
        );
        assertEq(ethBuyerAmountAfter, INITIAL_FUNDED - TRADE_AMOUNT);
    }

    function testBurnToken() public {
        vm.prank(msg.sender);
        bondingCurveToken.transfer(USER, TRADE_AMOUNT);

        uint256 tokenSupplyBefore = bondingCurveToken.totalSupply();
        uint256 tokenReserveBalanceBefore = bondingCurveToken.reserveBalance();
        uint256 tokenBuyerBalanceBefore = bondingCurveToken.balanceOf(USER);
        uint256 ethBuyerAmountBefore = USER.balance;

        assertEq(tokenSupplyBefore, INITIAL_SUPPLY);
        assertEq(tokenReserveBalanceBefore, INITIAL_RESERVE_BALANCE);
        assertEq(tokenBuyerBalanceBefore, TRADE_AMOUNT);
        assertEq(ethBuyerAmountBefore, INITIAL_FUNDED);

        vm.prank(USER);
        bondingCurveToken.burn(TRADE_AMOUNT);

        uint256 tokenSupplyAfter = bondingCurveToken.totalSupply();
        uint256 tokenReserveBalanceAfter = bondingCurveToken.reserveBalance();
        uint256 tokenBuyerBalanceAfter = bondingCurveToken.balanceOf(USER);
        uint256 ethBuyerAmountAfter = USER.balance;

        uint256 expectedReserveBalanceAfter = ((INITIAL_SUPPLY - TRADE_AMOUNT) *
            (INITIAL_SUPPLY - TRADE_AMOUNT) *
            INITIAL_RESERVE_BALANCE) /
            INITIAL_SUPPLY /
            INITIAL_SUPPLY;

        assertEq(tokenSupplyAfter, INITIAL_SUPPLY - TRADE_AMOUNT);
        assertApproxEqAbs(
            tokenReserveBalanceAfter,
            expectedReserveBalanceAfter,
            1
        );
        assertEq(tokenBuyerBalanceAfter, 0);
        assertApproxEqAbs(
            ethBuyerAmountAfter,
            INITIAL_FUNDED +
                INITIAL_RESERVE_BALANCE -
                expectedReserveBalanceAfter,
            1
        );
    }

    /**
     * test 2 minting actions, with different reserve balances in contract
     */
    function testMintTokenAtHigherReserve() public {
        uint256 tokenBuyerBalanceBefore = bondingCurveToken.balanceOf(USER);

        vm.prank(USER);
        bondingCurveToken.mint{value: TRADE_AMOUNT}();

        uint256 tokenBuyerBalanceAfter = bondingCurveToken.balanceOf(USER);
        uint256 mintedAmount1 = tokenBuyerBalanceAfter -
            tokenBuyerBalanceBefore;

        tokenBuyerBalanceBefore = tokenBuyerBalanceAfter;

        vm.prank(USER);
        bondingCurveToken.mint{value: TRADE_AMOUNT}();

        tokenBuyerBalanceAfter = bondingCurveToken.balanceOf(USER);
        uint256 mintedAmount2 = tokenBuyerBalanceAfter -
            tokenBuyerBalanceBefore;

        assertGt(mintedAmount1, mintedAmount2);
    }

    /**
     * test 2 burning actions, with different reserve balances in contract
     */
    function testBurnTokenAtLowerReserve() public {
        vm.prank(msg.sender);
        bondingCurveToken.transfer(USER, TRADE_AMOUNT);
        uint256 ethBuyerAmountBefore = USER.balance;

        vm.prank(USER);
        bondingCurveToken.burn(TRADE_AMOUNT / 2);

        uint256 ethBuyerAmountAfter = USER.balance;
        uint256 withdrawAmount1 = ethBuyerAmountAfter - ethBuyerAmountBefore;

        ethBuyerAmountBefore = ethBuyerAmountAfter;

        vm.prank(USER);
        bondingCurveToken.burn(TRADE_AMOUNT / 2);

        ethBuyerAmountAfter = USER.balance;
        uint256 withdrawAmount2 = ethBuyerAmountAfter - ethBuyerAmountBefore;

        assertGt(withdrawAmount1, withdrawAmount2);
    }
}

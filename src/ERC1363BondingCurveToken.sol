// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC1363Receiver, ERC1363} from "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {BancorFormula} from "lib/BancorFormula.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title linear Bonding Curve Token
 * @author Ryan
 * @notice
 * @dev  Bonding curve contract based on Bacor formula,my current implemention is linear bonding curve.
 *
 * 1: I use any ERC1363 token as purchase token, user can only use this purchase token to buy BondingCurveToken.
 *
 * 2: How to calculate how many BondingCurveToken should be minted  based on the buyer's token amount.
 * Use Bacor formula, and set the initialreserveBalance,initialSupply,RESERVE_RATION to make the linear curve. the details can see the test case.
 *
 * 3: If the initialSupply and initialreserveBalance are zero, It's can't calculate the price.So It's necessay to init these value and it's also a part of setting
 * the Bacor formula.
 */

contract ERC1363BondingCurveToken is
    Initializable,
    Ownable2Step,
    ERC1363,
    IERC1363Receiver,
    BancorFormula,
    ReentrancyGuard
{
    /*
    reserve ratio, represented in ppm, 1-1000000
    1/3 corresponds to y= multiple * x^2
    1/2 corresponds to y= multiple * x
    2/3 corresponds to y= multiple * x^1/2
    multiple will depends on contract initialization,
    specificallytotalAmount and reserveBalance parameters
    we might want to add an 'initialize' function that will allow
    the owner to send ether to the contract and mint a given amount of tokens
    */
    uint32 private immutable RESERVE_RATION = 500_000;

    ERC1363 private reserveToken;

    /**
     *
     * @param sender the buyer
     * @param mintAmount how many bondingCurve Token will be minted
     * @param depositAmount how many reserveToken  will be deposited
     */
    event CurvedMint(address indexed sender, uint256 indexed mintAmount, uint256 depositAmount);
    /**
     *
     * @param sender the seller
     * @param burnAmount how many bondingCurve Token will be sell
     * @param redeemAmount how many reserveToken will be send to the bondingCurve contract
     */
    event CurvedBurn(address indexed sender, uint256 indexed burnAmount, uint256 redeemAmount);

    /**
     * check if msg sender has enough BCT to burn.
     */
    modifier validEnoughBCT(uint256 burnAmount) {
        require(burnAmount > 0 && balanceOf(msg.sender) >= burnAmount, "No enough BCT to burn");
        _;
    }

    /**
     * check if deposit amount is non zero
     */
    modifier validMint(uint256 depositAmount) {
        require(depositAmount > 0, "Should transfer enough reserveToken");
        _;
    }

    constructor() Ownable(msg.sender) ERC20("ERC1363BondingCurveToken", "BCT1363") {}

    /**
     * @notice initial amount of reserve need to be sent to this contract in the initialization tx if not before.
     * @param initialSupply inital supply amount of BCT when initialize
     * @param initialReserveBalance inital amount of reserve when initialize
     */
    function initialize(uint256 initialSupply, uint256 initialReserveBalance, address _reserveToken)
        external
        payable
        onlyOwner
    {
        super.init();
        reserveToken = ERC1363(_reserveToken);
        _mint(msg.sender, initialSupply);
        require(
            reserveToken.transferFrom(msg.sender, address(this), initialReserveBalance),
            "ERC1363BondingCurveToken: invalid initial reserve balance."
        );
    }

    function onTransferReceived(address, address sender, uint256 depositAmount, bytes calldata)
        external
        override
        returns (bytes4)
    {
        require(msg.sender == address(reserveToken), "illegal call");
        _curvedMintFor(sender, depositAmount);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    /**
     * @param burnAmount amount of BCT to burn
     */
    function burn(uint256 burnAmount) external validEnoughBCT(burnAmount) nonReentrant {
        uint256 redeemAmount = _curvedBurnFor(msg.sender, burnAmount);
        require(reserveToken.transfer(msg.sender, redeemAmount), "Failed to send reserve token when burn");
    }

    /**
     * this view function helps to estimate how much BCT can be minted.
     * @param depositAmount amount of reserve token to deposit
     */
    function calculateCurvedMintReturn(uint256 depositAmount) public view returns (uint256) {
        return calculatePurchaseReturn(totalSupply(), reserveBalance() - depositAmount, RESERVE_RATION, depositAmount);
    }

    /**
     * this view function helps to estimate how much reserve token can be redeemed.
     * @param burnAmount amount of BCT to burn
     */
    function calculateCurvedBurnReturn(uint256 burnAmount) public view returns (uint256) {
        return calculateSaleReturn(totalSupply(), reserveBalance(), RESERVE_RATION, burnAmount);
    }

    function reserveBalance() public view returns (uint256) {
        return reserveToken.balanceOf(address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC1363Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function _curvedMintFor(address user, uint256 depositAmount) internal validMint(depositAmount) returns (uint256) {
        uint256 mintAmount = calculateCurvedMintReturn(depositAmount);
        _mint(user, mintAmount);

        emit CurvedMint(user, mintAmount, depositAmount);
        return mintAmount;
    }

    function _curvedBurnFor(address user, uint256 burnAmount) internal returns (uint256) {
        uint256 redeemAmount = calculateCurvedBurnReturn(burnAmount);

        _burn(user, burnAmount);
        emit CurvedBurn(user, burnAmount, redeemAmount);
        return redeemAmount;
    }
}

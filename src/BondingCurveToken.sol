// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

//import {ERC1363} from "@erc1363/contracts/token/ERC1363/ERC1363.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
 * 1: I use native ETH as purchase token, user can only use ETH to buy BCT.
 *
 * 2: How to calculate how many BondingCurveToken should be minted  based on the buyer's token amount.
 * Use Bacor formula, and set the initialreserveBalance,initialSupply,RESERVE_RATION to make the linear curve. the details can see the test case.
 *
 * 3: If the initialSupply and initialreserveBalance are zero, It's can't calculate the price.So It's necessay to init these value and it's also a part of setting
 * the Bacor formula.
 *
 * ERC1363
 * https://github.com/vittominacori/erc1363-payable-token/blob/v5.1.2/contracts/token/ERC1363/ERC1363.sol
 */

contract BondingCurveToken is
    Initializable,
    Ownable2Step,
    ERC20,
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

    /**
     *
     * @param sender the buyer
     * @param mintAmount how many bondingCurve Token will be minted
     * @param depositAmount how many reserveToken  will be deposited
     */
    event CurvedMint(
        address indexed sender,
        uint256 indexed mintAmount,
        uint256 depositAmount
    );
    /**
     *
     * @param sender the seller
     * @param burnAmount how many bondingCurve Token will be sell
     * @param redeemAmount how many reserveToken will be send to the bondingCurve contract
     */
    event CurvedBurn(
        address indexed sender,
        uint256 indexed burnAmount,
        uint256 redeemAmount
    );

    modifier validEnoughBCT(uint256 burnAmount) {
        require(
            burnAmount > 0 && balanceOf(msg.sender) >= burnAmount,
            "No enough BCT to burn"
        );
        _;
    }

    modifier validMint(uint256 depositAmount) {
        require(depositAmount > 0, "Should transfer enough reserveToken");
        _;
    }

    constructor() Ownable(msg.sender) ERC20("BondingCurveToken", "BCT") {}

    function initialize(
        uint256 initialSupply,
        uint256 initialReserveBalance
    ) external payable onlyOwner {
        super.init();
        _mint(msg.sender, initialSupply);
        require(
            address(this).balance == initialReserveBalance,
            "BondingCurveToken: invalid initial reserve balance."
        );
    }

    function mint() external payable {
        _curvedMintFor(msg.sender, msg.value);
    }

    function burn(
        uint256 burnAmount
    ) external validEnoughBCT(burnAmount) nonReentrant {
        uint256 redeemAmount = _curvedBurnFor(msg.sender, burnAmount);
        (bool sent, ) = payable(msg.sender).call{value: redeemAmount}("");
        require(sent, "Failed to send ether when burn");
    }

    function calculateCurvedMintReturn(
        uint256 depositAmount
    ) public view returns (uint256) {
        return
            calculatePurchaseReturn(
                totalSupply(),
                reserveBalance() - depositAmount,
                RESERVE_RATION,
                depositAmount
            );
    }

    function calculateCurvedBurnReturn(
        uint256 burnAmount
    ) public view returns (uint256) {
        return
            calculateSaleReturn(
                totalSupply(),
                reserveBalance(),
                RESERVE_RATION,
                burnAmount
            );
    }

    function reserveBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _curvedMintFor(
        address user,
        uint256 depositAmount
    ) internal validMint(depositAmount) returns (uint256) {
        uint256 mintAmount = calculateCurvedMintReturn(depositAmount);
        _mint(user, mintAmount);

        emit CurvedMint(user, mintAmount, depositAmount);
        return mintAmount;
    }

    function _curvedBurnFor(
        address user,
        uint256 burnAmount
    ) internal returns (uint256) {
        uint256 redeemAmount = calculateCurvedBurnReturn(burnAmount);

        _burn(user, burnAmount);
        emit CurvedBurn(user, burnAmount, redeemAmount);
        return redeemAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title UntrustedEscrow
 * @author Ryan
 * @notice  a contract where a buyer can put an arbitrary ERC20 token into a contract and a seller can withdraw it 3 days later.
 */
contract UntrustedEscrow is Ownable2Step {
    using SafeERC20 for IERC20;
    using Math for uint256;

    struct Escrow {
        address buyer;
        address seller;
        address token;
        uint256 amount;
        uint256 releaseTime;
        bool isActive;
    }

    uint256 public LOCK_TIME = 3 days;
    mapping(bytes32 => Escrow) private escrows;

    event Deposit(
        bytes32 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256 amount,
        uint256 releaseTime,
        bool isActive
    );
    event Withdraw(bytes32 indexed escrowId);

    event updatedLockTime(uint256 newLockTime);

    constructor() Ownable(msg.sender) {}

    /**
     *
     * @param timeInDays lock time to wait before withdrawl
     */
    function updateLockTime(uint256 timeInDays) external onlyOwner {
        LOCK_TIME = timeInDays * 1 days;

        emit updatedLockTime(LOCK_TIME);
    }

    /**
     * @param seller seller address to withdraw fund
     * @param token erc20 token to deposit
     * @param amount amount to deposit
     * @return escrowId escrow Id for this action
     */
    function deposit(
        address seller,
        address token,
        uint256 amount
    ) external returns (bytes32) {
        require(seller != address(0), "Seller address cannot be zero");
        require(amount > 0, "Amount must be greater than zero");
        require(
            !(IERC20(token).balanceOf(msg.sender) < amount),
            "Amount must be less than or equal to balance"
        );

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(
            balanceAfter > balanceBefore,
            "Token balance lowers than or equals to before tx"
        );

        uint256 newReleaseTime = block.timestamp + LOCK_TIME;

        Escrow memory escrow = Escrow({
            buyer: msg.sender,
            seller: seller,
            token: token,
            amount: balanceAfter - balanceBefore,
            releaseTime: newReleaseTime,
            isActive: true
        });

        bytes32 escrowId = hashEscrow(escrow);

        escrows[escrowId] = escrow;
        emit Deposit(
            escrowId,
            msg.sender,
            seller,
            token,
            balanceAfter - balanceBefore,
            newReleaseTime,
            true
        );
        return escrowId;
    }

    /**
     * @param escrowId the escrow to withdraw fund from
     */
    function withdraw(bytes32 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.isActive, "Escrow is no longer active");
        require(
            escrow.releaseTime < block.timestamp,
            "Escrow is not yet released"
        );
        require(msg.sender == escrow.seller, "Only seller can withdraw");

        uint256 transferAmount = escrow.amount;
        escrow.amount = 0;
        escrow.isActive = false;

        emit Withdraw(escrowId);
        IERC20(escrow.token).safeTransfer(msg.sender, transferAmount);
    }

    /**
     * @param escrowId the escrow to show details
     */
    function getEscrowDetails(
        bytes32 escrowId
    ) external view returns (Escrow memory) {
        return escrows[escrowId];
    }

    /**
     * compute hash for an escorw given contents
     */
    function hashEscrow(Escrow memory escrow) internal pure returns (bytes32) {
        return keccak256(abi.encode(escrow));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenWithGodMode is Ownable2Step, ERC20 {
    constructor(
        uint256 _totalSupply
    ) Ownable(msg.sender) ERC20("TokenWithGodMode", "TWGM") {
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @dev Transfers tokens from one address to another address.
     * @dev If the msg.sender is the owner, it can transfer between any addresses, regardless of the restriction.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to be transferred.
     * @return true if the transfer was successful.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (msg.sender != owner()) {
            super.transferFrom(from, to, amount);
        } else {
            _transfer(from, to, amount);
        }
        return true;
    }
}

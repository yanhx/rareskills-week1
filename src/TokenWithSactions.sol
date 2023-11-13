// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenWithSactions
 * @author Ryan
 * @notice  a fungible token that allows owner to ban specified addresses from sending and receiving tokens.
 */
contract TokenWithSactions is Ownable2Step, ERC20 {
    mapping(address => bool) private blacklists;

    constructor(
        uint256 totalSupply
    ) Ownable(msg.sender) ERC20("TokenWithSactions", "TWS") {
        _mint(msg.sender, totalSupply);
    }

    /**
     * blacklist or remove an address from blacklist
     * @param _address The address to blacklist or remove from blacklist
     * @param isBlacklisting to blacklist or to remove from blacklist
     */
    function blacklist(
        address _address,
        bool isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = isBlacklisting;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    /**
     * Override the _update function in ERC20, to check if to or from address is in blacklist
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param value the amount of tokensto be transferred
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
        super._update(from, to, value);
    }
}

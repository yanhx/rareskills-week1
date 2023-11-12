// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenWithSactions is Ownable2Step, ERC20 {
    mapping(address => bool) public blacklists;

    constructor(
        uint256 _totalSupply
    ) Ownable(msg.sender) ERC20("TokenWithSactions", "TWS") {
        _mint(msg.sender, _totalSupply);
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
        super._update(from, to, value);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}

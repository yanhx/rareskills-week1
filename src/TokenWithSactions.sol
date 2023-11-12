// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract TokenWithSactions is Owned, ERC20 {
    mapping(address => bool) public blacklists;

    constructor(
        uint256 _totalSupply
    ) Owned(msg.sender) ERC20("TokenWithSaction", "TWS", 18) {
        _mint(msg.sender, _totalSupply);
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20WithFees is ERC20 {
    constructor() ERC20("MockERC20WithFees", "MOCKFEE") {
        _mint(msg.sender, 1_000_000_000e18);
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    // simply mock the transfer with some fees which be burned
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value - 100);
        _burn(from, 100);
        return true;
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value - 100);
        _burn(owner, 100);
        return true;
    }
}

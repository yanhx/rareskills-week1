// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockRebasingToken is ERC20 {
    uint256 private constant INITIAL_SUPPLY_ = 1_000_000_000 * 10 ** 18;
    uint256 private constant TOTAL_ =
        type(uint256).max - (type(uint256).max % INITIAL_SUPPLY_);

    uint256 private _totalSupply;
    uint256 private mul_;
    mapping(address => uint256) private balance_;

    constructor() ERC20("MockERC20Rebase", "MOCKREBASE") {
        _totalSupply = INITIAL_SUPPLY_;
        balance_[msg.sender] = TOTAL_;
        mul_ = TOTAL_ / _totalSupply;
    }

    function balanceOf(address _addr) public view override returns (uint256) {
        return balance_[_addr] / mul_;
    }

    function transfer(
        address _to,
        uint256 _value
    ) public override returns (bool) {
        uint256 value_ = _value * mul_;

        balance_[msg.sender] = balance_[msg.sender] - value_;
        balance_[_to] = balance_[_to] + value_;

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        uint256 value_ = _value * mul_;

        balance_[_from] = balance_[_from] - value_;
        balance_[_to] = balance_[_to] + value_;

        return true;
    }

    function rebase(int256 _supplyDelta) external returns (uint256) {
        if (_supplyDelta == 0) {
            return _totalSupply;
        }

        if (_supplyDelta < 0) {
            _totalSupply = _totalSupply - uint256(_supplyDelta * (-1));
        } else {
            _totalSupply = _totalSupply + uint256(_supplyDelta);
        }

        mul_ = TOTAL_ / _totalSupply;

        return _totalSupply;
    }
}

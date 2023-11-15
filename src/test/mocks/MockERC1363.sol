// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC1363} from "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC1363 is ERC1363 {
    constructor() ERC20("MockERC1363", "MOCK1363") {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}

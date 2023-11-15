// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC1363BondingCurveToken} from "../src/ERC1363BondingCurveToken.sol";
import {MockERC1363} from "../src/test/mocks/MockERC1363.sol";

contract DeployERC1363BondingCurveToken is Script {
    uint256 public constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address DEPLOYER = makeAddr("deployer");

    function run(uint256 initialSupply, uint256 initialReserveBalance)
        external
        returns (ERC1363BondingCurveToken, MockERC1363, address)
    {
        vm.startBroadcast(DEPLOYER);
        ERC1363BondingCurveToken bondingCurveToken = new ERC1363BondingCurveToken();
        MockERC1363 mockToken = new MockERC1363();
        mockToken.approve(address(bondingCurveToken), MAX_UINT);
        mockToken.mint(DEPLOYER, 10 ether);
        bondingCurveToken.initialize(initialSupply, initialReserveBalance, address(mockToken));
        vm.stopBroadcast();
        return (bondingCurveToken, mockToken, DEPLOYER);
    }
}

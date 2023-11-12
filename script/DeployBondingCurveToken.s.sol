// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {BondingCurveToken} from "../src/BondingCurveToken.sol";

contract DeployBondingCurveToken is Script {
    function run(
        uint256 initialSupply,
        uint256 initialReserveBalance
    ) external returns (BondingCurveToken) {
        vm.startBroadcast();
        BondingCurveToken bondingCurveToken = new BondingCurveToken();
        bondingCurveToken.initialize{value: initialReserveBalance}(
            initialSupply,
            initialReserveBalance
        );
        vm.stopBroadcast();
        return bondingCurveToken;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";

contract DeployUntrustedEscrow is Script {
    function run() external returns (UntrustedEscrow) {
        vm.startBroadcast();
        UntrustedEscrow untrustedEscrow = new UntrustedEscrow();
        vm.stopBroadcast();
        return untrustedEscrow;
    }
}

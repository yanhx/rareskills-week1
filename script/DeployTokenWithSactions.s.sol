// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {TokenWithSactions} from "../src/TokenWithSactions.sol";

contract DeployTokenWithSactions is Script {
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 ether;

    function run() external returns (TokenWithSactions) {
        vm.startBroadcast();
        TokenWithSactions tokenWithSactions = new TokenWithSactions(
            TOTAL_SUPPLY
        );
        vm.stopBroadcast();
        return tokenWithSactions;
    }
}

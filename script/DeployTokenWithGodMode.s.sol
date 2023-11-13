// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {TokenWithGodMode} from "../src/TokenWithGodMode.sol";

contract DeployTokenWithGodMode is Script {
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 ether;

    function run() external returns (TokenWithGodMode) {
        vm.startBroadcast();
        TokenWithGodMode tokenWithGodMode = new TokenWithGodMode(TOTAL_SUPPLY);
        vm.stopBroadcast();
        return tokenWithGodMode;
    }
}

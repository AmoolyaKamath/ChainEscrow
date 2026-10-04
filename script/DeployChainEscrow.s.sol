// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ChainEscrow} from "../src/ChainEscrow.sol";

contract DeployChainEscrow is Script {

    function run() external returns (ChainEscrow) {

        vm.startBroadcast();

        ChainEscrow escrow = new ChainEscrow();

        vm.stopBroadcast();

        return escrow;
    }
}
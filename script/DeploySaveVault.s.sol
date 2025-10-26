// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {SaveVault} from "../src/SaveVault.sol";

contract DeploySaveVault is Script {
    function run() external {
        deployContract();
    }

    function deployContract() public returns (SaveVault) {
        vm.startBroadcast();
        SaveVault saveVault = new SaveVault();
        vm.stopBroadcast();
        return saveVault;
    }
}

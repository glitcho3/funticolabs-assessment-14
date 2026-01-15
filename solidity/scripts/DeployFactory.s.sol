// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/Factory.sol";

contract DeployFactory is Script {
    Factory public factory;

    function run() external {
        // Uses PRIVATE_KEY from env
        vm.startBroadcast();

        factory = new Factory();

        vm.stopBroadcast();

        // Write deployed address to file
        //string memory path = "./deployments/factory.address";
        //vm.writeFile(path, vm.toString(address(factory)));
    }
}


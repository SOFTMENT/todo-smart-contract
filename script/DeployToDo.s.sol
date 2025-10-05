// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {ToDo} from "../src/ToDo.sol";

contract DeployToDo is Script {
    function run() external returns (ToDo) {
        vm.startBroadcast();
        ToDo todo = new ToDo();
        vm.stopBroadcast();
        return todo;
    }
}

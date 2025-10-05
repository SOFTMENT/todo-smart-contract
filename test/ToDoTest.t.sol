// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployToDo} from "../script/DeployToDo.s.sol";
import {ToDo, Task} from "../src/ToDo.sol";

contract ToDoTest is Test {
    DeployToDo deployer;
    ToDo todo;
    address VIJAY = makeAddr("VIJAY");

    function setUp() external {
        deployer = new DeployToDo();
        todo = deployer.run();
    }

    function testTaskCreatedSuccessfullyAndCorrect() public {
        vm.startPrank(VIJAY);
        todo.createNewTask("Cat Food", "I will buy cat food from bus stand.");
        Task memory task = todo.readTask(1);
        vm.stopPrank();
        assertEq(task.owner, VIJAY, "You are not owner");
        assertEq(task.taskId, 1);
        assertEq(task.title, "Cat Food");
        assertEq(task.description, "I will buy cat food from bus stand.");

        assertEq(task.isCompleted, false);
    }

    function testDeleteTask() public {
        vm.startPrank(VIJAY);
        uint256 id = todo.createNewTask(
            "Cat Food",
            "I will buy cat food from bus stand."
        );
        todo.deleteTask(id);
        vm.stopPrank();

        vm.expectRevert();
        vm.prank(VIJAY);
        todo.readTask(id);
    }

    function testSetMarkAsCompletedTask() public {
        vm.startPrank(VIJAY);
        todo.createNewTask("Cat Food", "I will buy cat food from bus stand.");
        todo.setTaskMarkAsCompleted(1);
        Task memory task = todo.readTask(1);
        vm.stopPrank();
        assertEq(task.isCompleted, true);
    }

    function testEditTask() public {
        vm.startPrank(VIJAY);
        todo.createNewTask("Cat Food", "I will buy cat food from bus stand.");
        todo.updateTask(
            1,
            "Dog Food",
            "I will buy cat food from bus stand tomorrow."
        );
        Task memory task = todo.readTask(1);
        vm.stopPrank();
        assertEq(task.title, "Dog Food");
        assertEq(
            task.description,
            "I will buy cat food from bus stand tomorrow."
        );
    }
}

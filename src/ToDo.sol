// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

struct Task {
    uint256 taskId;
    string title;
    string description;
    bool isCompleted;
    address owner;
}

contract ToDo {
    // -------- Types --------

    // -------- Storage --------
    mapping(uint256 => Task) private tasks;
    uint256 private _nextId = 1;

    // -------- Events --------
    event TaskCreated(
        uint256 indexed taskId,
        address indexed owner,
        string title
    );
    event TaskUpdated(uint256 indexed taskId, string title, string description);
    event TaskCompleted(uint256 indexed taskId);
    event TaskDeleted(uint256 indexed taskId);

    // -------- Errors --------
    error NotOwner();
    error TaskNotFound();
    error CompletedTaskImmutable();

    // -------- Modifiers --------
    modifier onlyOwner(uint256 id) {
        if (!_exists(id)) revert TaskNotFound();
        if (tasks[id].owner != msg.sender) revert NotOwner();
        _;
    }

    modifier notCompleted(uint256 id) {
        if (!_exists(id)) revert TaskNotFound();
        if (tasks[id].isCompleted) revert CompletedTaskImmutable();
        _;
    }

    // -------- Internal helpers --------
    function _exists(uint256 id) internal view returns (bool) {
        return tasks[id].owner != address(0);
    }

    // -------- CRUD --------
    function createNewTask(
        string memory title,
        string memory description
    ) external returns (uint256 id) {
        id = _nextId++;
        Task storage t = tasks[id];
        t.taskId = id;
        t.title = title;
        t.description = description;
        t.isCompleted = false;
        t.owner = msg.sender;
        emit TaskCreated(id, msg.sender, title);
    }

    function updateTask(
        uint256 id,
        string memory title,
        string memory description
    ) external onlyOwner(id) notCompleted(id) {
        Task storage t = tasks[id];
        t.title = title;
        t.description = description; // preserve t.isCompleted as-is
        emit TaskUpdated(id, title, description);
    }

    function setTaskMarkAsCompleted(
        uint256 id
    ) external onlyOwner(id) notCompleted(id) {
        tasks[id].isCompleted = true;
        emit TaskCompleted(id);
    }

    function deleteTask(uint256 id) external onlyOwner(id) {
        delete tasks[id];
        emit TaskDeleted(id);
    }

    // Owner-gated reader (keep if you want private reads)
    function readTask(
        uint256 id
    ) external view onlyOwner(id) returns (Task memory) {
        return tasks[id];
    }

    // Optional: public getter w/o owner gate
    function getTask(uint256 id) external view returns (Task memory) {
        if (!_exists(id)) revert TaskNotFound();
        return tasks[id];
    }

    // Optional: expose counters
    function nextId() external view returns (uint256) {
        return _nextId;
    }
}

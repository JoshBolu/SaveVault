// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

contract SaveVault {
    error SaveVault__VaultAlreadyExists();
    error SaveVault__VaultDoesNotExist();
    error SaveVault__LockPeriodNotOver();
    error SaveVault__TransferFailed();

    mapping(address => uint256) private balances;
    // where put an array for start and end time
    mapping(address => uint256[2]) private saveDurationPerAddress;

    event vaultCreated(
        address indexed user,
        uint256 startTime,
        uint256 endTime,
        uint256 vaultBalance
    );
    event fundsSaved(address indexed user, uint256 amountSaved);

    function createVault(uint256 lockPeriodInSecs) external {
        // checks if the person already has a vault
        if (balances[msg.sender] > 0) {
            revert SaveVault__VaultAlreadyExists();
        }
        balances[msg.sender] = 0;
        saveDurationPerAddress[msg.sender][0] = block.timestamp;
        saveDurationPerAddress[msg.sender][1] =
            block.timestamp +
            lockPeriodInSecs;
        emit vaultCreated(
            msg.sender,
            block.timestamp,
            block.timestamp + lockPeriodInSecs,
            balances[msg.sender]
        );
    }

    function saveFunds() external payable {
        if (saveDurationPerAddress[msg.sender][0] == 0) {
            revert SaveVault__VaultDoesNotExist();
        }
        balances[msg.sender] += msg.value;
        emit fundsSaved(msg.sender, msg.value);
    }

    function withdrawFunds() external payable {
        if (saveDurationPerAddress[msg.sender][0] == 0) {
            revert SaveVault__VaultDoesNotExist();
        }
        if (block.timestamp < saveDurationPerAddress[msg.sender][1]) {
            revert SaveVault__LockPeriodNotOver();
        }
        (bool success, ) = payable(msg.sender).call{
            value: balances[msg.sender]
        }("");
        if (!success) {
            revert SaveVault__TransferFailed();
        }
        balances[msg.sender] = 0;
        saveDurationPerAddress[msg.sender][0] = 0;
        saveDurationPerAddress[msg.sender][1] = 0;
    }

    /**** Getters *****/
    function viewBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function viewSaveDuration() external view returns (uint256[2] memory) {
        return saveDurationPerAddress[msg.sender];
    }
}

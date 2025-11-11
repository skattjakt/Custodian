// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Ownable contract
contract Ownable {
    address public owner;

    /// @dev Only owner can access this function
    error OnlyOwner();

    modifier onlyOwner() {
        require(owner == msg.sender, OnlyOwner());
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    /// @notice Change the owner, only callable by current owner
    /// @param newOwner The address of the new owner
    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

/// @title Pause implementation
contract Pausable is Ownable {
    bool public paused;

    /// @dev Contact is paused
    error ContractPaused();

    modifier whenNotPaused() {
        require(paused == false, ContractPaused());
        _;
    }

    constructor(address owner) Ownable(owner) {}

    /// @notice Pause the contract
    function pause() external onlyOwner {
        paused = true;
    }

    /// @notice Unpause the contract
    function unpause() external onlyOwner {
        paused = false;
    }
}

/// @title Implementation example of pause
contract ImplementationContract is Pausable {
    constructor(address owner) Pausable(owner) {}

    function pausedProtectedFunction() external whenNotPaused {}
}

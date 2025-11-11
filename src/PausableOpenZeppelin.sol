// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

//import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract PausableContract is Ownable, Pausable {
    constructor(address owner) Ownable(owner) {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

contract ImplementationContract is PausableContract {
    constructor(address owner) PausableContract(owner) {}

    function pausedProtectedFunction() external whenNotPaused {}
}

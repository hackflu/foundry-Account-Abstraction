// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    IAccount
} from "../../lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {
    PackedUserOperation
} from "../../lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract MinimialAccount is IAccount {
    // entry point -> address(minimalAccount)

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override returns (uint256 validationData) {
        return 0;
    }
}

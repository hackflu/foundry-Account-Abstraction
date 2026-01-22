// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOps is Script {
    using MessageHashUtils for bytes32;
    function run() public {}

    function generatedSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
    ) public returns (PackedUserOperation memory) {
        // 1 generate the unsigned data
        uint256 nonce = IEntryPoint(config.entryPoint).getNonce(minimalAccount, 0);
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);
        // get user ophash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        // 2 .signed and return it
        /**
         * The order of v, r,s should be : r ,s v for creating the signature
         */
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        view
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 100000; // 100k gas
        uint128 callGasLimit = 200000; // 200k gas
        uint128 maxPriorityFeePerGas = 1e9; // 1 gwei
        uint128 maxFeePerGas = 10e9; // 10 gwei
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32((uint256(verificationGasLimit) << 128) | uint256(callGasLimit)),
            preVerificationGas: 50000,
            gasFees: bytes32((uint256(maxPriorityFeePerGas) << 128) | uint256(maxFeePerGas)),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}

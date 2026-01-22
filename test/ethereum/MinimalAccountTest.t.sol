// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
// Change these lines in MinimalAccountTest.t.sol
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployScript} from "script/DeployScript.s.sol";
import {SendPackedUserOps, PackedUserOperation, IEntryPoint, MessageHashUtils} from "script/SendPackedUserOps.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccounTest is Test {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    SendPackedUserOps sendPackedUserOps;
    uint256 constant AMOUNT_TO_MINT = 1e18;
    address randomUser = makeAddr("bundler");

    function setUp() public {
        DeployScript deployScript = new DeployScript();
        (helperConfig, minimalAccount) = deployScript.deployMinimalAccount();
        usdc = new ERC20Mock();
        sendPackedUserOps = new SendPackedUserOps();
    }

    // USDC approval

    function testOwnerCanExecute() public {
        //Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0, "Initial balance is zero");
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT_TO_MINT);

        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);
        //Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT_TO_MINT, "USDC minted to account");
    }

    function testNonOwnerCannnotCommands() public {
        // Arrage
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT_TO_MINT);

        // Act
        // Assert
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector));
        minimalAccount.execute(dest, value, functionData);
    }

    function testRecoverOp() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT_TO_MINT);
        bytes memory wrapperInCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOps.generatedSignedUserOperation(
            wrapperInCallData, helperConfig.getConfig(), address(minimalAccount)
        );
        // Act
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
        address actualSigner = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        assertEq(actualSigner, minimalAccount.owner());
    }

    // 1. Sign User Ops
    // 2 . Call validate userops
    // 3. Assert the return is correct
    function testValidationofUserOps() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT_TO_MINT);
        bytes memory wrapperInCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOperation = sendPackedUserOps.generatedSignedUserOperation(
            wrapperInCallData, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOperation);
        uint256 missingAccountFunds = 1e18;
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validatedData = minimalAccount.validateUserOp(packedUserOperation, userOpHash, missingAccountFunds);

        console.log("The data : ", validatedData);
        assertEq(validatedData, 0);
    }

    function testPointCanExecuteCommands() public {
        //Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT_TO_MINT);
        bytes memory wrapperInCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOperation = sendPackedUserOps.generatedSignedUserOperation(
            wrapperInCallData, helperConfig.getConfig(), address(minimalAccount)
        );

        vm.deal(address(minimalAccount), 100 ether);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOperation;

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        // Act
        address entryPoint = helperConfig.getConfig().entryPoint;
        // Assert
        console.log("tx  origin : ", tx.origin);
        console.log("length : ", address(0x123).code.length);
        vm.prank(randomUser, randomUser);
        IEntryPoint(entryPoint).handleOps(ops, payable(randomUser));

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT_TO_MINT);
    }
}

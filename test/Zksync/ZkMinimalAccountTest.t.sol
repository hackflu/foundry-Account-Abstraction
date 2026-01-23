// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {ZkMinimalAccount} from "../../src/Zksync/ZkMinimalAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {
    Transaction,
    MemoryTransactionHelper
} from "@foundry-era-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "@foundry-era-contracts/contracts/interfaces/IAccount.sol";
import {
    MessageHashUtils
} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {
    BOOTLOADER_FORMAL_ADDRESS
} from "@foundry-era-contracts/contracts/Constants.sol";

contract ZkMinimalAccountTest is Test {
    using MessageHashUtils for bytes32;
    ZkMinimalAccount minimalAccount;
    ERC20Mock mockToken;
    uint256 constant AMOUNT = 1e18;
    bytes32 constant EMPTY_BYTES32 = hex"";
    address constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        minimalAccount = new ZkMinimalAccount();
        minimalAccount.transferOwnership(ANVIL_DEFAULT_ACCOUNT);
        mockToken = new ERC20Mock();
        vm.deal(address(minimalAccount), AMOUNT);
    }

    function testZkOwnerCanExecuteCommands() public {
        // Arrange
        address dest = address(mockToken);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        Transaction memory tx = _createUnsignedTransaction(
            address(minimalAccount),
            113,
            dest,
            value,
            functionData
        );

        // Act
        vm.prank(minimalAccount.owner());
        minimalAccount.executeTransaction(EMPTY_BYTES32, EMPTY_BYTES32, tx);
        // Assert
        assertEq(
            mockToken.balanceOf(address(minimalAccount)),
            AMOUNT,
            "Token minted to account"
        );
    }
    // this  where i am testing
    function testZkValidateTransaction() public {
        //Arrange
        address dest = address(mockToken);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        Transaction memory tx = _createUnsignedTransaction(
            address(minimalAccount),
            113,
            dest,
            value,
            functionData
        );
        // Act
        tx = _signedTransaction(tx);
        // console.log("Signed Tx : ", tx);

        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magicData = minimalAccount.validateTransaction(
            EMPTY_BYTES32,
            EMPTY_BYTES32,
            tx
        );

        // Assert
        assertEq(magicData, ACCOUNT_VALIDATION_SUCCESS_MAGIC);
    }

    /////////////////////////////////////////////////////
    ////////////////// helper function //////////////////
    ////////////////////////////////////////////////////

    function _signedTransaction(
        Transaction memory _transaction
    ) internal view returns (Transaction memory) {
        bytes32 usignedTransactionData = MemoryTransactionHelper.encodeHash(
            _transaction
        );
        // bytes32 digest = usignedTransactionData.toEthSignedMessageHash();
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, usignedTransactionData);
        Transaction memory signTransaction = _transaction;
        signTransaction.signature = abi.encodePacked(r, s, v);
        return signTransaction;
    }

    function _createUnsignedTransaction(
        address from,
        uint8 transactionType,
        address to,
        uint256 value,
        bytes memory data
    ) internal view returns (Transaction memory) {
        uint256 nonce = vm.getNonce(address(minimalAccount));
        console.log("THE NONCE IS : ", nonce);
        bytes32[] memory factoryDeps = new bytes32[](0);
        return
            Transaction({
                txType: transactionType, // type 113
                from: uint256(uint160(from)),
                to: uint256(uint160(to)),
                gasLimit: 2000000,
                gasPerPubdataByteLimit: 50000,
                maxFeePerGas: 250000000, // 10 gwei
                maxPriorityFeePerGas: 10_000_000, // 1 gwei
                paymaster: 0,
                nonce: nonce,
                value: value, // 0
                reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
                data: data,
                signature: hex"",
                factoryDeps: factoryDeps,
                paymasterInput: hex"",
                reservedDynamic: hex""
            });
    }
}

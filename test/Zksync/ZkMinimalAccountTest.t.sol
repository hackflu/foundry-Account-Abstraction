// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {ZkMinimalAccount} from "../../src/Zksync/ZkMinimalAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Transaction} from "@foundry-era-contracts/contracts/libraries/MemoryTransactionHelper.sol";

contract ZkMinimalAccountTest is Test {
    ZkMinimalAccount minimalAccount;
    ERC20Mock mockToken;
    uint256 constant AMOUNT = 1e18;
    bytes32 constant EMPTY_BYTES32 = hex"";

    function setUp() public {
        minimalAccount = new ZkMinimalAccount();
        mockToken = new ERC20Mock();
    }

    function testZkOwnerCanExecuteCommands() public {
        // Arrange
        address dest = address(mockToken);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount),AMOUNT);

        Transaction memory tx = _createUnsignedTransaction(address(minimalAccount), 113, dest, value, functionData);
        // Act
        vm.prank(minimalAccount.owner());
        minimalAccount.executeTransaction(EMPTY_BYTES32 , EMPTY_BYTES32,tx);
        // Assert
        assertEq(mockToken.balanceOf(address(minimalAccount)), AMOUNT, "Token minted to account");
    }



    /////////////////////////////////////////////////////
    ////////////////// helper function //////////////////
    ////////////////////////////////////////////////////
    function _createUnsignedTransaction(address from , uint8 transactionType, address to, uint256 value , bytes memory data )
    internal view returns(Transaction memory){
        uint256 nonce = vm.getNonce(address(minimalAccount));
        bytes32[] memory factoryDeps = new bytes32[](0);
        return Transaction({
            txType : transactionType, // type 113
            from : uint256(uint160(from)),
            to : uint256(uint160(to)),
            gasLimit : 100_00_00,
            gasPerPubdataByteLimit : 100_00_00,
            maxFeePerGas : 10_00_00_000, // 10 gwei
            maxPriorityFeePerGas : 1_00_00_000, // 1 gwei
            paymaster : 0,
            nonce : nonce,
            value : value, // 0
            reserved : [uint256(0), uint256(0), uint256(0), uint256(0)],
            data : data,
            signature : hex"",
            factoryDeps: factoryDeps,
            paymasterInput: hex"",
            reservedDynamic: hex""
        });
    }
}
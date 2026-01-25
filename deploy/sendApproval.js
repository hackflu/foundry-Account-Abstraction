const { Wallet, Provider, Contract, utils, types, EIP712Signer } = require("zksync-ethers");
const { ethers } = require("ethers");
const { vars } = require("hardhat/config");
const fs = require("fs");

async function main() {
    console.log("Initiating the approval script...");
    
    // Configuration
    const ZK_MINIMAL_ADDRESS = "0x63127D9Eb6E2e7e67CF045026dA12B16F712B178";
    const RANDOM_APPROVER = "0x9EA9b0cc1919def1A3CfAEF4F7A66eE3c36F86fC";
    const USDC_ZKSYNC = "0x5249Fd99f1C1aE9B04C65427257Fc3B8cD976620"; // ZKsync Sepolia USDC
    const AMOUNT = 10000000; // 10 USDC (assuming 6 decimals)

    // Setup provider and wallet
    const PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");
    const RPC_URL = vars.get("ALCHEMY_RPC");

    const provider = new Provider(RPC_URL);
    const wallet = new Wallet(PRIVATE_KEY, provider);

    console.log("Wallet address:", wallet.address);
    console.log("AA Account address:", ZK_MINIMAL_ADDRESS);

    // Load ABIs
    const zkMinimalAbi = JSON.parse(
        fs.readFileSync("./zkout/ZkMinimalAccount.sol/ZkMinimalAccount.json", "utf8")
    )["abi"];
    
    const usdcAbi = JSON.parse(
        fs.readFileSync("./zkout/IERC20.sol/IERC20.json", "utf8")
    )["abi"];

    // Create contract instances
    const aaContract = new Contract(ZK_MINIMAL_ADDRESS, zkMinimalAbi, wallet);
    const usdcContract = new Contract(USDC_ZKSYNC, usdcAbi, wallet);

    // Check AA account balance
    const aaBalance = await provider.getBalance(ZK_MINIMAL_ADDRESS);
    console.log("AA Account ETH balance:", ethers.formatEther(aaBalance), "ETH");

    if (aaBalance === 0n) {
        throw new Error("AA account has no ETH for gas fees!");
    }

    // Prepare approval transaction data
    console.log("\nPreparing USDC approval transaction...");
    const approvalData = await usdcContract.approve.populateTransaction(
        RANDOM_APPROVER,
        AMOUNT
    );

    // Estimate gas
    const gasLimit = await provider.estimateGas({
        ...approvalData,
        from: wallet.address,
    });

    const feeData = await provider.getFeeData();
    const gasPrice = feeData.gasPrice;

    console.log("Estimated gas limit:", gasLimit.toString());
    console.log("Gas price:", ethers.formatUnits(gasPrice, "gwei"), "gwei");

    // Get current nonce
    const nonce = await provider.getTransactionCount(ZK_MINIMAL_ADDRESS);
    console.log("AA account nonce:", nonce);

    // Build AA transaction
    const aaTx = {
        ...approvalData,
        from: ZK_MINIMAL_ADDRESS,
        gasLimit: gasLimit,
        gasPrice: gasPrice,
        chainId: (await provider.getNetwork()).chainId,
        nonce: nonce,
        type: 113,
        value: 0n,
        customData: {
            gasPerPubdata: utils.DEFAULT_GAS_PER_PUBDATA_LIMIT,
        },
    };

    // Sign the transaction
    console.log("\nSigning transaction...");
    const signedTxHash = EIP712Signer.getSignedDigest(aaTx);
    
    const signature = ethers.concat([
        ethers.Signature.from(wallet.signingKey.sign(signedTxHash)).serialized,
    ]);

    console.log("Signature:", signature);

    // Add custom signature to transaction
    aaTx.customData = {
        ...aaTx.customData,
        customSignature: signature,
    };

    // Broadcast transaction
    console.log("\nBroadcasting transaction...");
    const sentTx = await provider.broadcastTransaction(
        types.Transaction.from(aaTx).serialized
    );

    console.log("✅ Transaction sent!");
    console.log("Transaction hash:", sentTx.hash);
    console.log("Explorer:", `https://sepolia.explorer.zksync.io/tx/${sentTx.hash}`);

    // Wait for confirmation
    console.log("\nWaiting for confirmation...");
    const receipt = await sentTx.wait();

    console.log("✅ Transaction confirmed!");
    console.log("Block number:", receipt.blockNumber);
    console.log("Status:", receipt.status === 1 ? "Success" : "Failed");

    // Check new nonce
    const newNonce = await provider.getTransactionCount(ZK_MINIMAL_ADDRESS);
    console.log("\nAA account nonce after transaction:", newNonce);

    // Verify approval
    const allowance = await usdcContract.allowance(ZK_MINIMAL_ADDRESS, RANDOM_APPROVER);
    console.log("\nApproved amount:", allowance.toString(), "USDC");
}

main()
    .then(() => {
        console.log("\n✅ Script completed successfully!");
        process.exit(0);
    })
    .catch((error) => {
        console.error("\n❌ Error:", error);
        process.exit(1);
    });
const {Deploy} = require("@matterlabs/hardhat-zksync-deploy");
const { Wallet, Provider, ContractFactory } = require("zksync-ethers");
const { vars } = require("hardhat/config");
const fs = require("fs");

async function main() {
    console.log("Initated the Deploying phase");

    const PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");
    const RPC_URL = vars.get("ALCHEMY_RPC");

    const provider = new Provider(RPC_URL);
    const wallet = new Wallet(PRIVATE_KEY,provider);
    const nonce = await provider.getTransactionCount(wallet.address);
    console.log("Current nonce:", nonce);
    console.log("Wallet address:", wallet.address);
    console.log("The current wallet address : ", wallet.address);

    // deploying the contract
    // const abi = JSON.parse(fs.readFileSync("./out/ZkMinimalAccount.sol/ZkMinimalAccount.json", "utf8"))["abi"]
    const artifiact_bytecode = JSON.parse(fs.readFileSync("./zkout/ZkMinimalAccount.sol/ZkMinimalAccount.json", "utf8"))["bytecode"]["object"]
    const artifiact_abi = JSON.parse(fs.readFileSync("./zkout/ZkMinimalAccount.sol/ZkMinimalAccount.json", "utf8"))["abi"]


    const ContractName = "ZkMinimalAccount";

    console.log(`The deploying contract is : ${ContractName}`);

    const contractFactory = new ContractFactory(artifiact_abi, artifiact_bytecode, wallet,"createAccount");

    const constructorArgs = [];
    const contract = await contractFactory.deploy({
        nonce : nonce,
        constructorArgs : constructorArgs
    });
    await contract.waitForDeployment();

    console.log(`zkMinimalAccount deployed to: ${await contract.getAddress()}`)
    console.log(`With transaction hash: ${(await contract.deploymentTransaction())}`)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })

// module.exports = main;
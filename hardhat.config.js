require('@matterlabs/hardhat-zksync-deploy');
require('@matterlabs/hardhat-zksync-solc');
const { vars } = require("hardhat/config");

const ZKSYNC_NETWORK_RPC = vars.get("ALCHEMY_RPC");
const SEPOLIA_PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");

module.exports = {
    solidity: {
        version: "0.8.19"
    },
    zksolc: {
        version: "1.5.7", // or another specific version
    },
    // this defaultName always match the network name
    defaultNetwork: "ZkSyncSepolia",
    networks: {
        ZkSyncSepolia: {    // <= must match with this
            url: ZKSYNC_NETWORK_RPC,
            ethNetwork: "sepolia",
            zksync: true,
            accounts: [SEPOLIA_PRIVATE_KEY]
        }
    }
};
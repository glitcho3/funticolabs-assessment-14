// server/tests/checkProvider.js
const { ethers } = require('ethers');

const RPC_URL = process.env.RPC_URL || 'http://127.0.0.1:8545';
//const RPC_URL = process.env.RPC_URL || 'http://0.0.0.0:8545';

async function main() {
  try {
    const provider = new ethers.JsonRpcProvider(RPC_URL);

    const blockNumber = await provider.getBlockNumber();
    console.log(` Provider ready. Current block: ${blockNumber}`);
    process.exit(0);
  } catch (err) {
    console.error(' Provider not reachable:', err.message);
    process.exit(1);
  }
}

main();


const path = require('path');

let deployInfo;
let factoryAbi;

try {
  deployInfo = require(path.resolve(
    process.cwd(),
    'solidity/deploy-info/deploy-localnet.json'
  ));

  factoryAbi = require(path.resolve(
    process.cwd(),
    'solidity/build/Factory.sol/Factory.json'
  )).abi;

} catch (err) {
  throw new Error('Solidity artifacts not available');
}

function getContractInfoByAddress(address) {
  if (!address || typeof address !== 'string') return null;

  if (address.toLowerCase() !== deployInfo.deployedTo.toLowerCase()) {
    return null;
  }

  return {
    address: deployInfo.deployedTo,
    transactionHash: deployInfo.transactionHash,
    methods: factoryAbi
      .filter(x => x.type === 'function')
      .map(x => x.name)
  };
}

module.exports = {
  getContractInfoByAddress
};


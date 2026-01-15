const path = require('path');

let deployInfo;
let factoryAbi;

try {
  deployInfo = require(path.resolve(
    process.cwd(),
    'solidity/deploy-info/deploy-localnet.json'
  ));
  console.log(deployInfo)
  factoryAbi = require(path.resolve(
    process.cwd(),
    'solidity/build/Factory.sol/Factory.json'
  )).abi;
  console.log(factoryAbi)
} catch (err) {
  console.error('Solidity artifacts not available', err);
}


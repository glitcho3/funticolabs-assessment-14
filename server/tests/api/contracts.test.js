const request = require('supertest');
const fs = require('fs');
const path = require('path');
const app = require('../../app');

const deployInfoPath = path.join(
  __dirname,
  '../../../solidity/deploy-info/deploy-localnet.json'
);

const abiPath = path.join(
  __dirname,
  '../../../solidity/build/Factory.sol/Factory.json'
);

let deployInfo = null;
let contractABI = null;

if (fs.existsSync(deployInfoPath)) {
  deployInfo = JSON.parse(fs.readFileSync(deployInfoPath, 'utf8'));
}

if (fs.existsSync(abiPath)) {
  const abiJson = JSON.parse(fs.readFileSync(abiPath, 'utf8'));
  contractABI = abiJson.abi;
}


async function safeGet(url) {
  try {
    return await request(app).get(url);
  } catch (err) {
    return {
      statusCode: 500,
      body: {
        error: err.message || 'Unhandled request error',
      },
    };
  }
}

function printResult(label, ok, details = '') {
  const status = ok ? 'PASS' : 'FAIL';
  console.log(`  ${label}: ${status}${details ? ` (${details})` : ''}`);
}

// Test runner

async function runTests() {
  console.log('\n==============================');
  console.log('API INTEGRATION TESTS');
  console.log('Contracts endpoints');
  console.log('==============================\n');


  console.log('Preflight checks');

  printResult(
    'Deploy info present',
    !!deployInfo,
    deployInfo ? `address=${deployInfo.deployedTo}` : 'deploy-localnet.json missing'
  );

  printResult(
    'Contract ABI present',
    !!contractABI,
    contractABI ? `entries=${contractABI.length}` : 'Factory.json missing'
  );

  console.log('');

  // Test 1: GET /contracts/                                       

  console.log('Test 1: GET /contracts/');
  const res1 = await safeGet('/contracts/');

  printResult('HTTP 200', res1.statusCode === 200, `status=${res1.statusCode}`);
  printResult('Body is array', Array.isArray(res1.body));
  printResult(
    'Contracts length readable',
    Array.isArray(res1.body),
    Array.isArray(res1.body) ? `length=${res1.body.length}` : 'invalid body'
  );

  console.log('');

  // Test 2: GET /contracts/count                                  

  console.log('Test 2: GET /contracts/count');
  const res2 = await safeGet('/contracts/count');

  printResult('HTTP 200', res2.statusCode === 200, `status=${res2.statusCode}`);
  printResult(
    'Count is number',
    typeof res2.body.count === 'number',
    `count=${res2.body.count}`
  );

  console.log('');


  // Test 3: GET /contracts/by-address/:address                    

  if (deployInfo && deployInfo.deployedTo) {
    console.log('Test 3: GET /contracts/by-address/:address');

    const res3 = await safeGet(
      `/contracts/by-address/${deployInfo.deployedTo}`
    );

    printResult('HTTP 200', res3.statusCode === 200, `status=${res3.statusCode}`);
    printResult(
      'Instance present',
      !!res3.body.instance,
      res3.body.instance ? 'instance found' : 'no instance'
    );

    console.log('');
  } else {
    console.log('Test 3: SKIPPED (no deployed contract address)\n');
  }

   process.exit(0);
}

runTests();

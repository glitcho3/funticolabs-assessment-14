const request = require('supertest');
const fs = require('fs');
const path = require('path');
const app = require('../../app');

const deployInfoPath = path.join(__dirname, '../../../solidity/deploy-info/deploy-localnet.json');

const abiPath = path.join(__dirname, '../../../solidity/build/Factory.sol/Factory.json');
const abiJson = JSON.parse(fs.readFileSync(abiPath, 'utf8'));
const contractABI = abiJson.abi;
// Carga del deploy info
const deployInfo = fs.existsSync(deployInfoPath) 
  ? JSON.parse(fs.readFileSync(deployInfoPath, 'utf8'))
  : null;

// Helper para capturar errores de llamadas a la API
async function safeGet(url) {
  try {
    return await request(app).get(url);
  } catch (err) {
    console.error(`SAFE GET ${url} failed:`, err.message || err.reason);
    return { statusCode: 500, body: {} };
  }
}

async function runTests() {
  console.log('Starting API tests...\n');
  console.log('Testing Contracts API\n');

  // Test 1: GET /contracts/
  console.log('Test 1: GET /contracts/');
  const res1 = await safeGet('/contracts/');
  console.log(`  Status: ${res1.statusCode} [${res1.statusCode === 200 ? 'PASS' : 'FAIL'}]`);
  console.log(`  Is Array: ${Array.isArray(res1.body) ? 'PASS' : 'FAIL'}`);
  console.log(`  Contracts: ${res1.body.length || 0}\n`);

  // Test 2: GET /contracts/count
  console.log('Test 2: GET /contracts/count');
  const res2 = await safeGet('/contracts/count');
  console.log(`  Status: ${res2.statusCode} [${res2.statusCode === 200 ? 'PASS' : 'FAIL'}]`);
  console.log(`  Count: ${res2.body.count || 0} [${typeof res2.body.count === 'number' ? 'PASS' : 'FAIL'}]\n`);

  // Test 3: GET /contracts/by-address/:address
  if (deployInfo && deployInfo.deployedTo) {
    console.log('Test 3: GET /contracts/by-address/:address');
    const res4 = await safeGet(`/contracts/by-address/${deployInfo.deployedTo}`);
    console.log(`  Status: ${res4.statusCode} [${res4.statusCode === 200 ? 'PASS' : 'FAIL'}]`);
    console.log(`  Has instance: ${res4.body.instance ? 'PASS' : 'FAIL'}\n`);
  } else {
    console.log('Test 4: SKIPPED: no deployed address\n');
  }

  console.log('All tests completed\n');
  process.exit(0);
}

runTests();

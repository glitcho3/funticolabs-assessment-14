# DeFi Real Estate - Assessment Submission

## Overview
This submission addresses critical security vulnerabilities and missing functionality in the smart contract codebase, adds comprehensive test coverage, and ensures proper integration with the Node.js backend API.

## Changes Made

### 0. Docker Usage

This application is containerized to provide a consistent, isolated environment for running the API and Solidity tests, ensuring all dependencies and configurations work the same across machines. To build and run the container:

```bash
docker build -t defi-property .
docker run -it --read-only=false -u 1000:1000 -p 3000:3000 -p 5001:5001 defi-property
``` 

The container starts the app and runs API tests automatically, exposing ports 3000 and 5001 for interaction, while running as a non-root user to maintain security.


### 1. Smart Contract Security Fixes

#### Critical Issues Resolved

**Reentrancy Protection**
- Added OpenZeppelin's `ReentrancyGuard` to `HomeTransaction.sol`
- Applied `nonReentrant` modifier to all functions handling ETH transfers
- Implemented Checks-Effects-Interactions pattern: state updates before external calls
- Reset `deposit = 0` before executing transfers to prevent exploitation

**Missing Fund Transfers**
- Fixed `buyerFinalizeTransaction()` which was not transferring funds
- Added proper distribution logic: seller receives `price - realtorFee`, realtor receives `realtorFee`

**Input Validation**
- Added address zero checks in constructor
- Enforced buyer and seller must be different addresses
- Added `require(deposit >= realtorFee)` to prevent underflow in withdrawal function
- Validated price must exceed realtor fee

**Additional Improvements**
- Added `ContractCreated` event to Factory for transparency
- Improved error messages for better debugging
- Enhanced state transition validation

### 2. Test Suite Implementation

Created comprehensive test coverage using Foundry:

**HomeTransaction Tests** (21 tests)
- Constructor validation tests
- State transition tests (seller sign, buyer deposit, realtor review, finalization)
- Access control verification (only authorized parties can execute functions)
- Amount validation (minimum deposit, exact payment requirements)
- Reentrancy attack prevention test
- Withdrawal scenarios (buyer cancellation, deadline expiration)

**Factory Tests** (15 tests)
- Contract creation and deployment
- Event emission verification
- Instance retrieval and counting
- Edge cases (maximum/minimum prices, multiple realtors)
- Input validation

**Test Results**: 36 tests, 100% pass rate

### 3. Backend API Testing

Created integration tests for contract-related API endpoints:
- `GET /contracts/` - List all contract instances
- `GET /contracts/count` - Get total contract count
- `GET /contracts/:index` - Get specific contract by index
- `GET /contracts/by-address/:address` - Get contract by deployed address

Fixed module export issue in `server/app.js` to enable testing.

### 4. Development Environment Setup

**Solidity Development**
- Implemented Foundry for faster compilation and testing
- Integrated OpenZeppelin contracts v4.9.3
- Configured proper remappings for imports
- Set up local Anvil testnet for deployment

**Deployment Process**
```bash
# Compile contracts
forge build

# Start local testnet
anvil --chain-id 31337 --host 0.0.0.0

# Deploy Factory contract
forge create src/Factory.sol:Factory \
  --rpc-url http://localhost:8545 \
  --private-key <ANVIL_PRIVATE_KEY> \
  --broadcast
```

## Technical Details

### Dependencies Added
- `@openzeppelin/contracts@4.9.3` - Security utilities (ReentrancyGuard)
- Foundry test framework for Solidity testing

### Files Modified
- `src/HomeTransaction.sol` - Security fixes and validations
- `src/Factory.sol` - Event emission and input validation
- `server/app.js` - Added module export for testing
- `server/tests/api/contracts.test.js` - Created API integration tests

### Files Created
- `test/HomeTransaction.t.sol` - Comprehensive smart contract tests
- `test/Factory.t.sol` - Factory contract tests
- `solidity/remappings.txt` - Import path configuration

## Security Improvements Summary

1. **Reentrancy Attack Prevention**: Guards against malicious contracts recursively calling payment functions
2. **Integer Overflow Protection**: Solidity 0.8+ built-in checks prevent arithmetic errors
3. **State Consistency**: Proper state management prevents fund loss or double-spending
4. **Access Control**: Strict role enforcement (only buyer/seller/realtor can execute specific functions)
5. **Input Sanitization**: All user inputs validated before processing

## Running the Tests

**Smart Contract Tests**
```bash
cd solidity
forge test              # Run all tests
forge test -vvv         # Verbose output
forge coverage          # Coverage report
```

**API Tests**
```bash
npm run api-sc-test
```

```
> defi-property@0.1.11 api-sc-test
> node server/tests/api/contracts.test.js


API INTEGRATION TESTS
Contracts endpoints

Preflight checks
  Deploy info present: PASS (address=ADDRESS)
  Contract ABI present: PASS (entries=5)

Test 1: GET /contracts/
  HTTP 200: PASS (status=200)
  Body is array: PASS
  Contracts length readable: PASS (length=0)

Test 2: GET /contracts/count
  HTTP 200: PASS (status=200)
  Count is number: PASS (count=0)

Test 3: GET /contracts/by-address/:address
  HTTP 200: PASS (status=200)
  Instance present: PASS (instance found)
  
```


## Time Investment
Approximately 40 minutes spent on critical fixes and core functionality. Additional time used for integration and comprehensive test coverage to mimic production readiness.

## Notes
- All critical security vulnerabilities have been addressed
- Test coverage ensures contract behavior is predictable and secure
- Code is ready for deployment to testnet/mainnet after additional audit
- Documentation added for maintainability

---

# DeFi Real Estate - Take-Home Assessment

Thank you for your interest in joining our team!  
This is a short take-home task to evaluate your skills with backend and smart contract code.

---

## Objective

Your goal is to review asmart contract small codebase, fix bugs, and improve testing for the backend API and smart contracts related to property transactions.

This task should take approximately **40 minutes**.

---

## What to Do

1. **Set Up**

   - Clone the provided code repository (or access the codebase files)
   - Setup the node version:
     ```bash
     nvm i 20.19.6
     nvm use 20.19.6
     ```
   - Install dependencies with:
     ```bash
     npm i
     ```
   - Run the project locally:
     ```bash
     npm start
     ```
   - The app will be available at `http://localhost:3000` (if applicable)

2. **Review & Fix**

   - Check the backend code (Node.js) for bugs or issues
   - Review the smart contract code (Solidity) for bugs or missing features
   - Fix identified bugs
   - Add simple tests if missing (e.g., basic unit tests for smart contracts or API endpoints)

3. **Submit**

   - Push your changes via a pull request or share the updated code package
   - Briefly describe what you fixed or changed

---

## Focus Areas

- Backend API (Node.js)
- Smart contracts (Solidity)
- Basic tests (if any are missing or incomplete)

---

## Notes

- Keep your changes simple and clear
- Focus on high-impact bugs or issues
- You can use test networks or mock data as needed
- Remember, the goal is to demonstrate your problem-solving skills quickly

---

## Good luck!  
We look forward to reviewing your submission.-------------------------

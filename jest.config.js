module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/server/tests/**/*.test.js'],
  modulePathIgnorePatterns: [
    '<rootDir>/solidity/',
    '<rootDir>/build/',
    '<rootDir>/node_modules/'
  ],
  transformIgnorePatterns: [
    'node_modules/(?!(axios)/)'
  ],
  testTimeout: 10000
};

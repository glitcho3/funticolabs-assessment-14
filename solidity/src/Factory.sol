pragma solidity ^0.8.27;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { HomeTransaction } from "./HomeTransaction.sol";


contract Factory is ReentrancyGuard {
    HomeTransaction[] contracts;

    event ContractCreated(
        address indexed contractAddress,
        address indexed seller,
        address indexed buyer,
        uint price
    );


  function create(
        string memory _address,
        string memory _zip,
        string memory _city,
        uint _realtorFee,
        uint _price,
        address payable _seller,
        address payable _buyer) public nonReentrant returns(HomeTransaction homeTransaction)  {
    require(_price > _realtorFee, "Invalid price or fee");
    require(_seller != address(0) && _buyer != address(0), "Invalid addresses");
    homeTransaction = new HomeTransaction(
      _address,
      _zip,
      _city,
      _realtorFee,
      _price,
      //msg.sender,
      payable(msg.sender),
      _seller,
      _buyer);
    contracts.push(homeTransaction);
    emit ContractCreated(address(homeTransaction), _seller, _buyer, _price);
  }


  function getInstance(uint index) public view returns (HomeTransaction instance) {
    require(index < contracts.length, "index out of range");


    instance = contracts[index];
  }

  function getInstances() public view returns (HomeTransaction[] memory instances) {
    instances = contracts;
  }

  function getInstanceCount() public view returns (uint count) {
    count = contracts.length;
  }
}

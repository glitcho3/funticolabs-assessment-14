pragma solidity ^0.8.27;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract HomeTransaction is ReentrancyGuard {
    // Constants
    uint constant TIME_BETWEEN_DEPOSIT_AND_FINALIZATION = 5 minutes;
    uint constant DEPOSIT_PERCENTAGE = 10;

    enum ContractState {
        WaitingSellerSignature,
        WaitingBuyerSignature,
        WaitingRealtorReview,
        WaitingFinalization,
        Finalized,
        Rejected }
    ContractState public contractState = ContractState.WaitingSellerSignature;


    // Roles acting on contract
    address payable public realtor;
    address payable public seller;
    address payable public buyer;

    // Contract details
    string public homeAddress;
    string public zip;
    string public city;
    uint public realtorFee;
    uint public price;

    // Set when buyer signs and pays deposit
    uint public deposit;
    uint public finalizeDeadline;

    // Set when realtor reviews closing conditions
    enum ClosingConditionsReview { Pending, Accepted, Rejected }
    ClosingConditionsReview closingConditionsReview = ClosingConditionsReview.Pending;

    constructor(
        string memory _address,
        string memory _zip,
        string memory _city,
        uint _realtorFee,
        uint _price,
        address payable _realtor,
        address payable _seller,
        address payable _buyer) public {
	require(_realtor != address(0) && _seller != address(0) && _buyer != address(0), "Invalid addresses");
        require(_seller != _buyer, "Seller and buyer must be different");
        require(_price >= _realtorFee, "Price needs to be more than realtor fee!");

        realtor = _realtor;
        seller = _seller;
        buyer = _buyer;
        homeAddress = _address;
        zip = _zip;
        city = _city;
        price = _price;
        realtorFee = _realtorFee;
    }

    function sellerSignContract() public payable {
        require(seller == msg.sender, "Only seller can sign contract");

        require(contractState == ContractState.WaitingSellerSignature, "Wrong contract state");

        contractState = ContractState.WaitingBuyerSignature;
    }

    function buyerSignContractAndPayDeposit() public payable nonReentrant {
        require(buyer == msg.sender, "Only buyer can sign contract");

        require(contractState == ContractState.WaitingBuyerSignature, "Wrong contract state");

	uint minDeposit = (price * DEPOSIT_PERCENTAGE) / 100;
        require(msg.value >= minDeposit && msg.value <= price,
		"Buyer needs to deposit between 10% and 100%");


        contractState = ContractState.WaitingRealtorReview;

        deposit = msg.value;
	finalizeDeadline = block.timestamp + TIME_BETWEEN_DEPOSIT_AND_FINALIZATION;

    }

    function realtorReviewedClosingConditions(bool accepted) public nonReentrant {

        require(realtor == msg.sender, "Only realtor can review closing conditions");

        require(contractState == ContractState.WaitingRealtorReview, "Wrong contract state");

        if (accepted) {
            closingConditionsReview = ClosingConditionsReview.Accepted;
            contractState = ContractState.WaitingFinalization;
        } else {
            closingConditionsReview = ClosingConditionsReview.Rejected;
            contractState = ContractState.Rejected;

            uint refundAmount = deposit;
            deposit = 0;
            buyer.transfer(refundAmount);
        }
    }

    function buyerFinalizeTransaction() public payable nonReentrant {
        require(buyer == msg.sender, "Only buyer can finalize transaction");

        require(contractState == ContractState.WaitingFinalization, "Wrong contract state");

        require(msg.value + deposit == price, "Buyer needs to pay the rest of the cost to finalize transaction");

        contractState = ContractState.Finalized;

	uint sellerAmount = price - realtorFee;
        deposit = 0;
	seller.transfer(sellerAmount);
        realtor.transfer(realtorFee);
    }

    function anyWithdrawFromTransaction() public nonReentrant {

        require(buyer == msg.sender || finalizeDeadline <= block.timestamp, "Only buyer can withdraw before transaction deadline");

        require(contractState == ContractState.WaitingFinalization, "Wrong contract state");

        contractState = ContractState.Rejected;

	uint sellerAmount = deposit - realtorFee;
        uint realtorAmount = realtorFee;

        deposit = 0;

        seller.transfer(sellerAmount);
        realtor.transfer(realtorAmount);
    }
}

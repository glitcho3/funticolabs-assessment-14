// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "../src/HomeTransaction.sol";
import "../src/Factory.sol";

contract HomeTransactionTest is Test {
    Factory public factory;
    HomeTransaction public transaction;
    
    address payable public realtor;
    address payable public seller;
    address payable public buyer;
    
    uint public constant PRICE = 100 ether;
    uint public constant REALTOR_FEE = 5 ether;
    uint public constant DEPOSIT_AMOUNT = 10 ether; // 10% of price
    
    function setUp() public {
        // Setup addresses with funds (avoid precompiled addresses 0x1-0x9)
        realtor = payable(address(0x100));
        seller = payable(address(0x200));
        buyer = payable(address(0x300));
        
        vm.deal(buyer, 200 ether);
        vm.deal(seller, 10 ether);
        
        // Deploy factory and create transaction
        factory = new Factory();
        
        vm.prank(realtor);
        transaction = factory.create(
            "123 Main St",
            "12345",
            "New York",
            REALTOR_FEE,
            PRICE,
            seller,
            buyer
        );
    }
    
    //  CONSTRUCTOR TESTS 
    
    function testConstructorSetsCorrectValues() public view {
        assertEq(transaction.realtor(), realtor);
        assertEq(transaction.seller(), seller);
        assertEq(transaction.buyer(), buyer);
        assertEq(transaction.price(), PRICE);
        assertEq(transaction.realtorFee(), REALTOR_FEE);
        assertEq(transaction.homeAddress(), "123 Main St");
    }
    
    function testConstructorRevertsOnInvalidAddresses() public {
        vm.expectRevert("Invalid addresses");
        vm.prank(realtor);
        new HomeTransaction(
            "123 Main St",
            "12345",
            "New York",
            REALTOR_FEE,
            PRICE,
            realtor,
            payable(address(0)), // Invalid seller
            buyer
        );
    }
    
    function testConstructorRevertsWhenSellerEqualsBuyer() public {
        vm.expectRevert("Seller and buyer must be different");
        vm.prank(realtor);
        new HomeTransaction(
            "123 Main St",
            "12345",
            "New York",
            REALTOR_FEE,
            PRICE,
            realtor,
            seller,
            seller // Same as seller
        );
    }
    
    function testConstructorRevertsOnInvalidPrice() public {
        vm.expectRevert("Price needs to be more than realtor fee!");
        vm.prank(realtor);
        new HomeTransaction(
            "123 Main St",
            "12345",
            "New York",
            REALTOR_FEE,
            4 ether, // Less than realtor fee
            realtor,
            seller,
            buyer
        );
    }
    
    //  SELLER SIGN CONTRACT TESTS 
    
    function testSellerCanSignContract() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        assertEq(
            uint(transaction.contractState()),
            uint(HomeTransaction.ContractState.WaitingBuyerSignature)
        );
    }
    
    function testOnlySellerCanSign() public {
        vm.prank(buyer);
        vm.expectRevert("Only seller can sign contract");
        transaction.sellerSignContract();
    }
    
    function testSellerCannotSignTwice() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(seller);
        vm.expectRevert("Wrong contract state");
        transaction.sellerSignContract();
    }
    
    //  BUYER SIGN AND DEPOSIT TESTS 
    
    function testBuyerCanSignAndPayDeposit() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        assertEq(transaction.deposit(), DEPOSIT_AMOUNT);
        assertEq(
            uint(transaction.contractState()),
            uint(HomeTransaction.ContractState.WaitingRealtorReview)
        );
        assertGt(transaction.finalizeDeadline(), block.timestamp);
    }
    
    function testBuyerCannotDepositLessThan10Percent() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        vm.expectRevert("Buyer needs to deposit between 10% and 100%");
        transaction.buyerSignContractAndPayDeposit{value: 5 ether}();
    }
    
    function testBuyerCannotDepositMoreThanPrice() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        vm.expectRevert("Buyer needs to deposit between 10% and 100%");
        transaction.buyerSignContractAndPayDeposit{value: 150 ether}();
    }
    
    function testOnlyBuyerCanDeposit() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(seller);
        vm.expectRevert("Only buyer can sign contract");
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
    }
    
    //  REALTOR REVIEW TESTS 
    
    function testRealtorCanAcceptConditions() public {
        // Setup: seller signs, buyer deposits
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        // Realtor accepts
        vm.prank(realtor);
        transaction.realtorReviewedClosingConditions(true);
        
        assertEq(
            uint(transaction.contractState()),
            uint(HomeTransaction.ContractState.WaitingFinalization)
        );
    }
    
    function testRealtorCanRejectAndRefundBuyer() public {
        uint buyerBalanceBefore = buyer.balance;
        
        // Setup: seller signs, buyer deposits
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        // Realtor rejects
        vm.prank(realtor);
        transaction.realtorReviewedClosingConditions(false);
        
        assertEq(
            uint(transaction.contractState()),
            uint(HomeTransaction.ContractState.Rejected)
        );
        assertEq(transaction.deposit(), 0);
        assertEq(buyer.balance, buyerBalanceBefore); // Buyer got refund
    }
    
    function testOnlyRealtorCanReview() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        vm.prank(buyer);
        vm.expectRevert("Only realtor can review closing conditions");
        transaction.realtorReviewedClosingConditions(true);
    }
    
    //  FINALIZE TRANSACTION TESTS 
    
    function testBuyerCanFinalizeTransaction() public {
        uint sellerBalanceBefore = seller.balance;
        uint realtorBalanceBefore = realtor.balance;
        
        // Full workflow
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        vm.prank(realtor);
        transaction.realtorReviewedClosingConditions(true);
        
        // Buyer finalizes
        uint remainingPayment = PRICE - DEPOSIT_AMOUNT;
        vm.prank(buyer);
        transaction.buyerFinalizeTransaction{value: remainingPayment}();
        
        assertEq(
            uint(transaction.contractState()),
            uint(HomeTransaction.ContractState.Finalized)
        );
        assertEq(transaction.deposit(), 0);
        assertEq(seller.balance, sellerBalanceBefore + PRICE - REALTOR_FEE);
        assertEq(realtor.balance, realtorBalanceBefore + REALTOR_FEE);
    }
    
    function testBuyerMustPayExactRemainingAmount() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        vm.prank(realtor);
        transaction.realtorReviewedClosingConditions(true);
        
        // Try to pay wrong amount
        vm.prank(buyer);
        vm.expectRevert("Buyer needs to pay the rest of the cost to finalize transaction");
        transaction.buyerFinalizeTransaction{value: 50 ether}();
    }
    
    function testOnlyBuyerCanFinalize() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        vm.prank(realtor);
        transaction.realtorReviewedClosingConditions(true);


        
        uint remainingPayment = PRICE - DEPOSIT_AMOUNT;
        vm.deal(seller, remainingPayment);
        vm.prank(seller);
        vm.expectRevert("Only buyer can finalize transaction");
        transaction.buyerFinalizeTransaction{value: remainingPayment}();
    }
    
    //  WITHDRAWAL TESTS 
    
    function testBuyerCanWithdrawBeforeDeadline() public {
        uint sellerBalanceBefore = seller.balance;
        uint realtorBalanceBefore = realtor.balance;
        
        // Setup to WaitingFinalization
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        vm.prank(realtor);
        transaction.realtorReviewedClosingConditions(true);
        
        // Buyer withdraws
        vm.prank(buyer);
        transaction.anyWithdrawFromTransaction();
        
        assertEq(
            uint(transaction.contractState()),
            uint(HomeTransaction.ContractState.Rejected)
        );
        assertEq(transaction.deposit(), 0);
        assertEq(seller.balance, sellerBalanceBefore + DEPOSIT_AMOUNT - REALTOR_FEE);
        assertEq(realtor.balance, realtorBalanceBefore + REALTOR_FEE);
    }
    
    function testAnyoneCanWithdrawAfterDeadline() public {
        uint sellerBalanceBefore = seller.balance;
        
        // Setup to WaitingFinalization
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        vm.prank(realtor);
        transaction.realtorReviewedClosingConditions(true);
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 6 minutes);
        
        // Anyone can withdraw
        vm.prank(seller);
        transaction.anyWithdrawFromTransaction();
        
        assertEq(
            uint(transaction.contractState()),
            uint(HomeTransaction.ContractState.Rejected)
        );
        assertEq(seller.balance, sellerBalanceBefore + DEPOSIT_AMOUNT - REALTOR_FEE);
    }
    
    function testNonBuyerCannotWithdrawBeforeDeadline() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        vm.prank(buyer);
        transaction.buyerSignContractAndPayDeposit{value: DEPOSIT_AMOUNT}();
        
        vm.prank(realtor);
        transaction.realtorReviewedClosingConditions(true);
        
        vm.prank(seller);
        vm.expectRevert("Only buyer can withdraw before transaction deadline");
        transaction.anyWithdrawFromTransaction();
    }
    
    //  REENTRANCY PROTECTION TESTS 
    
    function testReentrancyProtectionOnDeposit() public {
        vm.prank(seller);
        transaction.sellerSignContract();
        
        // Deploy malicious contract
        MaliciousDepositor attacker = new MaliciousDepositor(transaction);
        vm.deal(address(attacker), 20 ether);
        
        // Should revert on reentrancy attempt
        vm.expectRevert();
        attacker.attack();
    }
}

// Malicious contract to test reentrancy
contract MaliciousDepositor {
    HomeTransaction public target;
    uint public callCount;
    
    constructor(HomeTransaction _target) {
        target = _target;
    }
    
    function attack() external {
        target.buyerSignContractAndPayDeposit{value: 10 ether}();
    }
    
    receive() external payable {
        callCount++;
        if (callCount < 2) {
            target.buyerSignContractAndPayDeposit{value: 10 ether}();
        }
    }
}

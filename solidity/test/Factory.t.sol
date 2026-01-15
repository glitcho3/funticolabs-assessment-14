// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "../src/Factory.sol";
import "../src/HomeTransaction.sol";

contract FactoryTest is Test {
    Factory public factory;
    
    address payable public realtor;
    address payable public seller;
    address payable public buyer;
    
    uint public constant PRICE = 100 ether;
    uint public constant REALTOR_FEE = 5 ether;
    
    event ContractCreated(
        address indexed contractAddress,
        address indexed seller,
        address indexed buyer,
        uint price
    );
    
    function setUp() public {
        factory = new Factory();
        
        realtor = payable(address(0x100));
        seller = payable(address(0x200));
        buyer = payable(address(0x300));
    }
    
    //  CREATE CONTRACT TESTS 
    
    function testCanCreateHomeTransaction() public {
        vm.prank(realtor);
        HomeTransaction transaction = factory.create(
            "123 Main St",
            "12345",
            "New York",
            REALTOR_FEE,
            PRICE,
            seller,
            buyer
        );
        
        assertEq(address(transaction.realtor()), realtor);
        assertEq(address(transaction.seller()), seller);
        assertEq(address(transaction.buyer()), buyer);
        assertEq(transaction.price(), PRICE);
    }
    
    function testCreateEmitsEvent() public {
        vm.prank(realtor);
        
        vm.expectEmit(false, true, true, true);
        emit ContractCreated(address(0), seller, buyer, PRICE);
        
        factory.create(
            "123 Main St",
            "12345",
            "New York",
            REALTOR_FEE,
            PRICE,
            seller,
            buyer
        );
    }
    
    function testCreateRevertsOnInvalidPrice() public {
        vm.prank(realtor);
        vm.expectRevert("Invalid price or fee");
        factory.create(
            "123 Main St",
            "12345",
            "New York",
            REALTOR_FEE,
            4 ether, // Less than realtor fee
            seller,
            buyer
        );
    }
    
    function testCreateRevertsOnZeroAddress() public {
        vm.prank(realtor);
        vm.expectRevert("Invalid addresses");
        factory.create(
            "123 Main St",
            "12345",
            "New York",
            REALTOR_FEE,
            PRICE,
            payable(address(0)), // Invalid seller
            buyer
        );
    }
    
    function testCreateIncrementsInstanceCount() public {
        assertEq(factory.getInstanceCount(), 0);
        
        vm.prank(realtor);
        factory.create("123 Main St", "12345", "New York", REALTOR_FEE, PRICE, seller, buyer);
        assertEq(factory.getInstanceCount(), 1);
        
        vm.prank(realtor);
        factory.create("456 Oak Ave", "67890", "Boston", REALTOR_FEE, PRICE, seller, buyer);
        assertEq(factory.getInstanceCount(), 2);
    }
    
    //  GET INSTANCE TESTS 
    
    function testCanGetInstanceByIndex() public {
        vm.prank(realtor);
        HomeTransaction expected = factory.create(
            "123 Main St",
            "12345",
            "New York",
            REALTOR_FEE,
            PRICE,
            seller,
            buyer
        );
        
        HomeTransaction actual = factory.getInstance(0);
        assertEq(address(actual), address(expected));
    }
    
    function testGetInstanceRevertsOnOutOfBounds() public {
        vm.expectRevert("index out of range");
        factory.getInstance(0);
    }
    
    function testGetInstanceReturnsCorrectContract() public {
        vm.startPrank(realtor);
        HomeTransaction tx1 = factory.create("123 Main St", "12345", "NY", REALTOR_FEE, PRICE, seller, buyer);
        HomeTransaction tx2 = factory.create("456 Oak Ave", "67890", "LA", REALTOR_FEE, PRICE, seller, buyer);
        vm.stopPrank();
        
        assertEq(address(factory.getInstance(0)), address(tx1));
        assertEq(address(factory.getInstance(1)), address(tx2));
    }
    
    //  GET INSTANCES TESTS 
    
    function testGetInstancesReturnsEmptyArrayInitially() public view {
        HomeTransaction[] memory instances = factory.getInstances();
        assertEq(instances.length, 0);
    }
    
    function testGetInstancesReturnsAllContracts() public {
        vm.startPrank(realtor);
        factory.create("123 Main St", "12345", "NY", REALTOR_FEE, PRICE, seller, buyer);
        factory.create("456 Oak Ave", "67890", "LA", REALTOR_FEE, PRICE, seller, buyer);
        factory.create("789 Elm St", "11111", "SF", REALTOR_FEE, PRICE, seller, buyer);
        vm.stopPrank();
        
        HomeTransaction[] memory instances = factory.getInstances();
        assertEq(instances.length, 3);
    }
    
    //  GET INSTANCE COUNT TESTS 
    
    function testGetInstanceCountReturnsZeroInitially() public view {
        assertEq(factory.getInstanceCount(), 0);
    }
    
    function testGetInstanceCountIncrementsCorrectly() public {
        vm.startPrank(realtor);
        
        factory.create("123 Main St", "12345", "NY", REALTOR_FEE, PRICE, seller, buyer);
        assertEq(factory.getInstanceCount(), 1);
        
        factory.create("456 Oak Ave", "67890", "LA", REALTOR_FEE, PRICE, seller, buyer);
        assertEq(factory.getInstanceCount(), 2);
        
        factory.create("789 Elm St", "11111", "SF", REALTOR_FEE, PRICE, seller, buyer);
        assertEq(factory.getInstanceCount(), 3);
        
        vm.stopPrank();
    }
    
    //  MULTIPLE REALTORS TEST 
    
    function testMultipleRealtorsCanCreateContracts() public {
        address payable realtor1 = payable(address(0x400));
        address payable realtor2 = payable(address(0x500));
        
        vm.prank(realtor1);
        HomeTransaction tx1 = factory.create("123 Main St", "12345", "NY", REALTOR_FEE, PRICE, seller, buyer);
        
        vm.prank(realtor2);
        HomeTransaction tx2 = factory.create("456 Oak Ave", "67890", "LA", REALTOR_FEE, PRICE, seller, buyer);
        
        assertEq(address(tx1.realtor()), realtor1);
        assertEq(address(tx2.realtor()), realtor2);
        assertEq(factory.getInstanceCount(), 2);
    }
    
    //  EDGE CASES 
    
    function testCreateWithMaximumPrice() public {
        vm.prank(realtor);
        HomeTransaction transaction = factory.create(
            "123 Main St",
            "12345",
            "New York",
            1 ether,
            type(uint256).max,
            seller,
            buyer
        );
        
        assertEq(transaction.price(), type(uint256).max);
    }
    
    function testCreateWithMinimumValidPrice() public {
        vm.prank(realtor);
        HomeTransaction transaction = factory.create(
            "123 Main St",
            "12345",
            "New York",
            1 wei,
            2 wei, // Just above realtor fee
            seller,
            buyer
        );
        
        assertEq(transaction.price(), 2 wei);
    }
}

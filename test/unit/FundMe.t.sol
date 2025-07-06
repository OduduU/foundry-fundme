// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundme} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_VALUE = 10 ether;
    uint256 constant GAS_PRICE = 2;

    function setUp() external {
        DeployFundme deployFundMe = new DeployFundme();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_VALUE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    function testPriceFundFailWithoutEnoughEth() public {
        vm.expectRevert();

        fundMe.fund{value: 1000000}(); // 0.01 ETH, which is less than 5 USD at 2000 USD/ETH
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdateDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

        assertEq(amountFunded, SEND_VALUE);
    }

    function testRevertWithdrawWithoutOwner() public {
        vm.prank(USER);

        vm.expectRevert();

        fundMe.withdraw();
    }

    function testAddFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        address[] memory funders = fundMe.getFunders();

        assertEq(funder, USER);
        assertEq(funders.length, 1);
    }

    function testWithdrawWithASingleFunder() public funded {
        vm.txGasPrice(GAS_PRICE);
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        console.log("gasStart: %s", gasStart);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        console.log("gasEnd: %s", gasEnd);
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gasprice: %s", tx.gasprice);
        console.log("gasUsed: %s", gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
        assertEq(fundMe.getFunders().length, 0);
        assertEq(fundMe.getAddressToAmountFunded(USER), 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        address[] memory funders = new address[](numberOfFunders);

        for (uint160 i = 0; i < numberOfFunders; i++) {
            funders[i] = address(i + 1);
            hoax(funders[i], STARTING_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );

        for (uint256 i = 0; i < numberOfFunders; i++) {
            assertEq(fundMe.getAddressToAmountFunded(funders[i]), 0);
        }
    }

    function testWithdrawFromMultipleFundersCheap() public funded {
        uint160 numberOfFunders = 10;
        address[] memory funders = new address[](numberOfFunders);

        for (uint160 i = 0; i < numberOfFunders; i++) {
            funders[i] = address(i + 1);
            hoax(funders[i], STARTING_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheapWithdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );

        for (uint256 i = 0; i < numberOfFunders; i++) {
            assertEq(fundMe.getAddressToAmountFunded(funders[i]), 0);
        }
    }

    function testWithdrawFromMultipleFundersCcheap() public funded {
        uint160 numberOfFunders = 10;
        address[] memory funders = new address[](numberOfFunders);

        for (uint160 i = 0; i < numberOfFunders; i++) {
            funders[i] = address(i + 1);
            hoax(funders[i], STARTING_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.ccheapWithdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );

        for (uint256 i = 0; i < numberOfFunders; i++) {
            assertEq(fundMe.getAddressToAmountFunded(funders[i]), 0);
        }
    }
}

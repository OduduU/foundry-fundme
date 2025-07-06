// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__NotEnoughEth();
error FundMe__WithdrawalError();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;

    address private immutable I_OWNER;
    AggregatorV3Interface private s_priceFeed;

    constructor(address aggregatorV3InterfaceAddress) {
        I_OWNER = msg.sender;
        s_priceFeed = AggregatorV3Interface(aggregatorV3InterfaceAddress);
    }

    modifier onlyOwner() {
        if (msg.sender != I_OWNER) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__NotEnoughEth();
        }
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheapWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        // payable(msg.sender).transfer(address(this).balance);
        // bool success = payable(msg.sender).send(address(this).balance);
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );

        if (!sent) {
            revert FundMe__WithdrawalError();
        }
    }

    function ccheapWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        // payable(msg.sender).transfer(address(this).balance);
        // bool success = payable(msg.sender).send(address(this).balance);
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );

        if (!sent) {
            revert FundMe__WithdrawalError();
        }
    }

    function withdraw() public onlyOwner {
        for (
            uint funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        // payable(msg.sender).transfer(address(this).balance);
        // bool success = payable(msg.sender).send(address(this).balance);
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );

        if (!sent) {
            revert FundMe__WithdrawalError();
        }
    }

    function getVersion() public view returns (uint256) {
        uint256 version = PriceConverter.getVersion(s_priceFeed);

        return version;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getFunders() external view returns (address[] memory) {
        return s_funders;
    }

    function getOwner() external view returns (address) {
        return I_OWNER;
    }
}

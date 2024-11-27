// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  event Stake(address indexed Staker, uint256 amount);
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      deadline=block.timestamp+72 hours;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

  mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline;
    bool public openForWithdraw;
    bool public executed;

  function stake() public payable {
    require(block.timestamp < deadline, "Deadline reached");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

  function execute() public {
    require (block.timestamp >= deadline, "Deadline not reached");
    require (!executed, "Already executed");

    if (address(this).balance >= threshold){
      exampleExternalContract.complete{value: address(this).balance}();
      executed = true;
    }else{
      openForWithdraw = true;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

  function withdraw() public {
    require(openForWithdraw, "Not opened for withdraw");
    uint256 balance = balances[msg.sender];
    require(balance>0, "No balance to withdraw");
    balances[msg.sender] = 0;
    (bool sent, ) = msg.sender.call{value:balance}("");
    require(sent, "Failed to sent Ether");
  }
  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  function timeLeft() public view returns (uint256){
    if (block.timestamp >= deadline){
      return 0;
    }else{
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  
  receive() external payable{
    stake();
  }

}

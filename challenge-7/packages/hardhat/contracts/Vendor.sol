pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "./YourToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vendor is Ownable {
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event WithdrawETH(address owner, uint256 amount);

    YourToken public yourToken;

    uint256 public constant tokensPerEth = 100;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    // Payable function to buy tokens
    function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");

        uint256 amountToBuy = msg.value * tokensPerEth;

        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Vendor does not have enough tokens");

        yourToken.transfer(msg.sender, amountToBuy);

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    // Function to withdraw all ETH from the contract
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No ETH available for withdrawal");

        (bool success, ) = msg.sender.call{value: contractBalance}("");
        require(success, "Withdrawal failed");

        emit WithdrawETH(msg.sender, contractBalance);
    }
}

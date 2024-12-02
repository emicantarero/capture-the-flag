// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Streamer is Ownable {
  event Opened(address, uint256);
  event Challenged(address);
  event Withdrawn(address, uint256);
  event Closed(address);

  mapping(address => uint256) balances;
  mapping(address => uint256) canCloseAt;

  function fundChannel() public payable {
        
        require(balances[msg.sender] == 0, "Channel already exists");

        balances[msg.sender] = msg.value;

        emit Opened(msg.sender, msg.value);
    }

  function timeLeft(address channel) public view returns (uint256) {
    if (canCloseAt[channel] == 0 || canCloseAt[channel] < block.timestamp) {
      return 0;
    }

    return canCloseAt[channel] - block.timestamp;
  }

  function withdrawEarnings(Voucher calldata voucher) public {
    bytes32 hashed = keccak256(abi.encode(voucher.updatedBalance));

    bytes memory prefixed = abi.encodePacked("\x19Ethereum Signed Message:\n32", hashed);
    bytes32 prefixedHashed = keccak256(prefixed);

    bytes32 r = voucher.sig.r;
    bytes32 s = voucher.sig.s;
    uint8 v = voucher.sig.v;

    address signer = ecrecover(prefixedHashed, v, r, s);
    require(signer != address(0), "Invalid signature");

    require(balances[signer] > voucher.updatedBalance, "Insufficient channel balance");

    uint256 payment = balances[signer] - voucher.updatedBalance;
    balances[signer] = voucher.updatedBalance;

    address contractOwner = owner();
    payable(contractOwner).transfer(payment);

    emit Withdrawn(signer, payment);
  }


  function challengeChannel() public {
    require(balances[msg.sender] > 0, "No open channel to challenge");

    canCloseAt[msg.sender] = block.timestamp + 1 hours;

    emit Challenged(msg.sender);
}

function defundChannel() public {
    require(canCloseAt[msg.sender] > 0, "No closing channel to defund");

    require(block.timestamp >= canCloseAt[msg.sender], "Channel cannot be closed yet");

    uint256 remainingBalance = balances[msg.sender];
    require(remainingBalance > 0, "No funds to withdraw");

    balances[msg.sender] = 0;
    canCloseAt[msg.sender] = 0;

    payable(msg.sender).transfer(remainingBalance);

    emit Closed(msg.sender);
}


  struct Voucher {
    uint256 updatedBalance;
    Signature sig;
  }
  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (r, s, v);
    }
}

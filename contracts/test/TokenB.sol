pragma solidity >=0.4.21 <0.6.0;


import "../lib/openzeppelin-solidity/StandardToken.sol";

// Modified from OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-contracts
/**
 * @title TokenB
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract TokenB is StandardToken {

  string public constant name = "Token B";
  string public constant symbol = "BBB";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}

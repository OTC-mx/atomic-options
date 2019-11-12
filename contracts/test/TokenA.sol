pragma solidity >=0.4.21 <0.6.0;


import "../lib/openzeppelin-solidity/StandardToken.sol";

// Modified from OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-contracts
/**
 * @title TokenA
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract TokenA is StandardToken {

  string public constant name = "Token A";
  string public constant symbol = "AAA";
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

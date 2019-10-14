pragma solidity >=0.4.21 <0.6.0;

import "../lib/ERC20.sol";

/**
 * @title OptionTemplate
 * @dev Template for entire Option family
 */
contract OptionTemplate {

  // // Basic information
  // Buyer and issuer of the option
  address public issuer;
  address public buyer;
  // Address of the base (that you pay), asset (being bought)
  address public base_addr;
  address public asset_addr;

  // // Financial information
  // Fee
  uint256 public fee;
  // Asset volume traded
  uint256 public volume;
  // Option can be exercised between maturity_time and expiry_time
  uint256 public maturity_time;
  uint256 public expiry_time;

  // Contract states
  uint256 public state;
  uint256 public constant STATE_UNINITIALIZED = 0;
  uint256 public constant STATE_INITIALIZED = 1;
  uint256 public constant STATE_COLLATERALIZED = 2;
  uint256 public constant STATE_ACTIVE = 3;
  uint256 public constant STATE_EXERCISED = 4;
  uint256 public constant STATE_EXPIRED = 5;

  // // External contracts
  // Callable base and asset ERC20s
  ERC20 public base;
  ERC20 public asset;
  
  /*
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  */
}

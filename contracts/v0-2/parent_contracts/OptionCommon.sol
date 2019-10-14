pragma solidity >=0.4.21 <0.6.0;

import "../../lib/ERC20.sol";

/**
 * @title OptionCommon
 * @dev Template for entire Option family
 */
contract OptionCommon {
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

  // // Collateralizes option
  function collateralize() public {
    require(msg.sender == issuer);
    require(state == STATE_INITIALIZED);
    require(expiry_time > block.timestamp);

    bool asset_transfer = asset.transferFrom(issuer, address(this), volume);
    require(asset_transfer);

    state = STATE_COLLATERALIZED;
  }

  // // Pays fee to issuer
  function pay_fee() public {
    require(msg.sender == buyer);
    require(state == STATE_COLLATERALIZED);
    require(expiry_time > block.timestamp);

    bool base_transfer = base.transferFrom(buyer, issuer, fee);
    require(base_transfer);

    state = STATE_ACTIVE;
  }
}

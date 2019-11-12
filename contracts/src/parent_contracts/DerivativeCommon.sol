pragma solidity >=0.4.21 <0.6.0;

import "../../lib/openzeppelin-solidity/ERC20.sol";

/**
 * @title DerivativeCommon
 * @dev Template for all Derivatives
 */
contract DerivativeCommon {
  // // Basic information
  // Buyer and issuer of the option
  address public issuer;
  address public buyer;
  // Address of the base (that you pay), asset (being bought)
  address public base_addr;
  address public asset_addr;

  // // Financial information
  // Asset volume traded
  uint256 public volume;
  // Option can be exercised between maturity_time and expiry_time
  // Forward can be withdrawn any time after maturity_time
  uint256 public maturity_time;

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

  constructor(address _issuer, address _buyer,
              address _base_addr, address _asset_addr,
              uint256 _volume,
              uint256 _maturity_time) public {
    require(_base_addr != _asset_addr);

    issuer = _issuer;
    buyer = _buyer;
    base_addr = _base_addr;
    asset_addr = _asset_addr;
    volume = _volume;
    maturity_time = _maturity_time;

    base = ERC20(_base_addr);
    asset = ERC20(_asset_addr);

    state = STATE_INITIALIZED;
  }

  // // Collateralizes contract
  function collateralize() public {
    require(msg.sender == issuer);
    require(state == STATE_INITIALIZED);

    bool asset_transfer = asset.transferFrom(issuer, address(this), volume);
    require(asset_transfer);

    state = STATE_COLLATERALIZED;
  }

  // Transfer buyer/issuer of contract
  function transfer_issuer(address _to) public {
    require(msg.sender == issuer);
    issuer = _to;
  }

  function transfer_buyer(address _to) public {
    require(msg.sender == buyer);
    buyer = _to;
  }
}

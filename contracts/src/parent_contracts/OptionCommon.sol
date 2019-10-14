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

  constructor(address _issuer, address _buyer,
              address _base_addr, address _asset_addr,
              uint256 _fee,
              uint256 _volume,
              uint256 _maturity_time, uint256 _expiry_time) public {
    require(_base_addr != _asset_addr);
    require((_expiry_time > block.timestamp) && (_expiry_time > _maturity_time));

    issuer = _issuer;
    buyer = _buyer;
    base_addr = _base_addr;
    asset_addr = _asset_addr;
    fee = _fee;
    volume = _volume;
    maturity_time = _maturity_time;
    expiry_time = _expiry_time;

    base = ERC20(_base_addr);
    asset = ERC20(_asset_addr);

    state = STATE_INITIALIZED;
  }

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

  function exercise_internal(uint256 base_volume_exercised,
                              uint256 asset_volume_exercised) internal {
    require((expiry_time > block.timestamp) && (maturity_time <= block.timestamp));
    require((state == STATE_ACTIVE) || (state == STATE_EXERCISED));
    require(base_volume_exercised > 0);
    require((asset_volume_exercised > 0) && (asset_volume_exercised <= volume));

    bool base_transfer = base.transferFrom(buyer, issuer, base_volume_exercised);
    require(base_transfer);
    bool asset_transfer = asset.transfer(buyer, asset_volume_exercised);
    require(asset_transfer);

    volume = volume - asset_volume_exercised;

    state = STATE_EXERCISED;
  }

  function expire() public {
    require(msg.sender == issuer);
    require((expiry_time <= block.timestamp) ||
            (state == STATE_COLLATERALIZED) ||
            (volume == 0));
    require(state != STATE_EXPIRED);

    bool asset_transfer = asset.transfer(issuer, volume);
    require(asset_transfer);

    state = STATE_EXPIRED;
  }
}

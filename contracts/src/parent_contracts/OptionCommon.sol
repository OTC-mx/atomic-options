pragma solidity >=0.4.21 <0.6.0;

import "../../lib/openzeppelin-solidity/ERC20.sol";
import "./DerivativeCommon.sol";

/**
 * @title OptionCommon
 * @dev Template for entire Option family
 */
contract OptionCommon is DerivativeCommon {
  // // Financial information
  // Fee
  uint256 public fee;
  // Option can be exercised between maturity_time (declared in DerivativeCommon) and expiry_time
  uint256 public expiry_time;

  constructor(address _issuer, address _buyer,
              address _base_addr, address _asset_addr,
              uint256 _fee,
              uint256 _volume,
              uint256 _maturity_time, uint256 _expiry_time)
    DerivativeCommon(_issuer, _buyer,
                    _base_addr, _asset_addr,
                    _volume,
                    _maturity_time) public {
    require(_base_addr != _asset_addr);
    require((_expiry_time > block.timestamp) && (_expiry_time > _maturity_time));

    fee = _fee;
    expiry_time = _expiry_time;
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

  // // Exercise wrappers: required for abstraction
  // Should all throw errors
  function exercise_from_asset(uint256 asset_volume_exercised) public {
    require(false);
  }

  function exercise_from_base(uint256 base_volume_exercised) public {
    require(false);
  }

  function exercise_from_asset(uint256 strike_price_base,
                                uint256 strike_price_quote,
                                bytes32 salt,
                                uint256 asset_volume_exercised) public {
    require(false);
  }

  function exercise_from_base(uint256 strike_price_base,
                              uint256 strike_price_quote,
                              bytes32 salt,
                              uint256 base_volume_exercised) public {
    require(false);
  }
}

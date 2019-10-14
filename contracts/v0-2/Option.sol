pragma solidity >=0.4.21 <0.6.0;

import "../lib/ERC20.sol";
import "./OptionCommon.sol";

/**
 * @title Option
 * @dev Basic Option
 */
contract Option is OptionCommon {
  // // Strike price [i.e. (strike_price_quote * base_volume) / strike_price_base  = asset_volume]
  uint256 public strike_price_base;
  uint256 public strike_price_quote;

  constructor(address _issuer, address _buyer,
              address _base_addr, address _asset_addr,
              uint256 _fee,
              uint256 _strike_price_base, uint256 _strike_price_quote,
              uint256 _volume,
              uint256 _maturity_time, uint256 _expiry_time) public {
    require(state == STATE_UNINITIALIZED);
    require(_base_addr != _asset_addr);
    require((_expiry_time > block.timestamp) && (_expiry_time > _maturity_time));

    issuer = _issuer;
    buyer = _buyer;
    base_addr = _base_addr;
    asset_addr = _asset_addr;
    fee = _fee;
    strike_price_base = _strike_price_base;
    strike_price_quote = _strike_price_quote;
    volume = _volume;
    maturity_time = _maturity_time;
    expiry_time = _expiry_time;

    base = ERC20(_base_addr);
    asset = ERC20(_asset_addr);

    state = STATE_INITIALIZED;
  }
}

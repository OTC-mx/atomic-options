pragma solidity >=0.4.21 <0.6.0;

import "../lib/ERC20.sol";
import "./parent_contracts/IndivisibleCommon.sol";

/**
 * @title StandardOption
 * @dev Basic Option
 */
contract StandardOption is IndivisibleCommon {
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

  // // Exercise wrappers: can only be called by buyer.
  // Specify how many to buy
  function exercise_from_asset(uint256 asset_volume_exercised) public {
    require(msg.sender == buyer);

    uint256 base_volume_exercised = (asset_volume_exercised * strike_price_base) / strike_price_quote;

    exercise_internal(base_volume_exercised, asset_volume_exercised);
  }

  // Specify how many to sell
  function exercise_from_base(uint256 base_volume_exercised) public {
    assert(msg.sender == buyer);

    uint256 asset_volume_exercised = (base_volume_exercised * strike_price_quote) / strike_price_base;

    exercise_internal(base_volume_exercised, asset_volume_exercised);
  }

  // Returns all information about the contract in one go
  function get_info() public view returns (address, address, address, address,
                                            uint256, uint256, uint256,
                                            uint256, uint256, uint256, uint256) {
    return(issuer, buyer, base_addr, asset_addr,
            fee, strike_price_base, strike_price_quote,
            volume, maturity_time, expiry_time, state);
  }
}

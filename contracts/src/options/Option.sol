pragma solidity >=0.4.21 <0.6.0;

import "../../lib/openzeppelin-solidity/ERC20.sol";
import "../parent_contracts/OptionCommon.sol";

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
              uint256 _maturity_time, uint256 _expiry_time)
    OptionCommon(_issuer, _buyer,
                  _base_addr, _asset_addr,
                  _fee,
                  _volume,
                  _maturity_time, _expiry_time) public {
    strike_price_base = _strike_price_base;
    strike_price_quote = _strike_price_quote;
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
    require(msg.sender == buyer);

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

pragma solidity >=0.4.21 <0.6.0;

import "../options/Option.sol";

contract OptionFactory {
  event NewOption(address option);

  mapping(address => bool) public created_options;

  function create_option(address _issuer, address _buyer,
                          address _base_addr, address _asset_addr,
                          uint256 _fee,
                          uint256 _strike_price_base, uint256 _strike_price_quote,
                          uint256 _volume,
                          uint256 _maturity_time, uint256 _expiry_time)
      public returns (address) {
    Option option = new Option(_issuer, _buyer,
                                _base_addr, _asset_addr,
                                _fee,
                                _strike_price_base, _strike_price_quote,
                                _volume,
                                _maturity_time, _expiry_time);
    emit NewOption(address(option));
    created_options[address(option)] = true;
    return address(option);
  }

  function get_created_option(address created_option_address) public view returns (bool) {
    return created_options[created_option_address];
  }
}

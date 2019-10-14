pragma solidity >=0.4.21 <0.6.0;

import "../options/SilentOption.sol";

contract SilentOptionFactory {
  function create_standard_option(address _issuer, address _buyer,
                                  address _base_addr, address _asset_addr,
                                  uint256 _fee,
                                  bytes32 _strike_price_base_hash, bytes32 _strike_price_quote_hash,
                                  uint256 _volume,
                                  uint256 _maturity_time, uint256 _expiry_time)
                                    public returns (address) {
    SilentOption silent_option = new SilentOption(
                                    _issuer, _buyer,
                                    _base_addr, _asset_addr,
                                    _fee,
                                    _strike_price_base_hash, _strike_price_quote_hash,
                                    _volume,
                                    _maturity_time, _expiry_time);
    return address(silent_option);
  }
}

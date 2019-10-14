pragma solidity >=0.4.21 <0.6.0;

import "../options/TokenizedOption.sol";

contract TokenizedOptionFactory {
  event NewTokenizedOption(address tokenized_option);
  function create_tokenized_option(address _issuer, address _buyer,
                                  address _base_addr, address _asset_addr,
                                  uint256 _fee,
                                  uint256 _strike_price_base, uint256 _strike_price_quote,
                                  uint256 _volume,
                                  uint256 _maturity_time, uint256 _expiry_time)
                                    public returns (address) {
    TokenizedOption tokenized_option = new TokenizedOption(
                                    _issuer, _buyer,
                                    _base_addr, _asset_addr,
                                    _fee,
                                    _strike_price_base, _strike_price_quote,
                                    _volume,
                                    _maturity_time, _expiry_time);
    emit NewTokenizedOption(address(tokenized_option));
    return address(tokenized_option);
  }
}

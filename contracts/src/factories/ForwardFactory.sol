pragma solidity >=0.4.21 <0.6.0;

import "../forwards/Forward.sol";

contract ForwardFactory {
  event NewForward(address forward);

  mapping(address => bool) public created_forwards;

  function create_forward(address _issuer, address _buyer,
                          address _base_addr, address _asset_addr,
                          uint256 _fee,
                          uint256 _strike_price_base, uint256 _strike_price_quote,
                          uint256 _volume,
                          uint256 _maturity_time)
      public returns (address) {
    Forward forward = new Forward(_issuer, _buyer,
                                  _base_addr, _asset_addr,
                                  _fee,
                                  _strike_price_base, _strike_price_quote,
                                  _volume,
                                  _maturity_time);
    created_forwards[address(forward)] = true;
    emit NewForward(address(forward));
    return address(forward);
  }

  function get_created_forward(address created_forward_address) public view returns (bool) {
    return created_forwards[created_forward_address];
  }
}

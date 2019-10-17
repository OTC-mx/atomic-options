pragma solidity >=0.4.21 <0.6.0;

import "../forwards/ManagedForward.sol";

contract ManagedForwardFactory {
  event NewManagedForward(address managed_forward);

  mapping(address => bool) public created_managed_forwards;

  function create_managed_forward(address _issuer, address _buyer,
                                  address _base_addr, address _asset_addr,
                                  uint256 _strike_price_base, uint256 _strike_price_quote,
                                  uint256 _volume,
                                  uint256 _maturity_time,
                                  address _issuer_portfolio_addr, address _buyer_portfolio_addr)
      public returns (address) {
    ManagedForward managed_forward = new ManagedForward(_issuer, _buyer,
                                                        _base_addr, _asset_addr,
                                                        _strike_price_base, _strike_price_quote,
                                                        _volume,
                                                        _maturity_time,
                                                        _issuer_portfolio_addr, _buyer_portfolio_addr);
    created_managed_forwards[address(managed_forward)] = true;
    emit NewManagedForward(address(managed_forward));
    return address(managed_forward);
  }

  function get_created_forward(address created_forward_address) public view returns (bool) {
    return created_managed_forwards[created_forward_address];
  }
}

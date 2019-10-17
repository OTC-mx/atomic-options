pragma solidity >=0.4.21 <0.6.0;

import "../auxiliary/Portfolio.sol";

contract PortfolioFactory {
  event NewPortfolio(address portfolio);

  mapping(address => bool) public created_portfolios;

  function create_portfolio(address _base_addr, address _asset_addr,
                            address _managed_forward_factory_addr) public returns (address) {
    Portfolio portfolio = new Portfolio(_base_addr, _asset_addr, msg.sender, _managed_forward_factory_addr);
    created_portfolios[address(portfolio)] = true;
    emit NewPortfolio(address(portfolio));
    return address(portfolio);
  }
}

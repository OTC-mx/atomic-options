pragma solidity >=0.4.21 <0.6.0;

import "../auxiliary/CashSettler.sol";

contract CashSettlerFactory {
  event NewCashSettler(address cash_settler);

  mapping(address => bool) public created_cash_settlers;

  function create_cash_settler(address _base_addr, address _asset_addr,
                                address _option_addr,
                                address _flash_lender_addr,
                                address _base_exchange_addr, address _asset_exchange_addr) public returns (address) {
    CashSettler cash_settler = new CashSettler(_base_addr, _asset_addr, msg.sender,
                                                _option_addr,
                                                _flash_lender_addr,
                                                _base_exchange_addr, _asset_exchange_addr);
    created_cash_settlers[address(cash_settler)] = true;
    emit NewCashSettler(address(cash_settler));
    return address(cash_settler);
  }
}

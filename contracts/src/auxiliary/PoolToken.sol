pragma solidity >=0.4.21 <0.6.0;

import "../../lib/StandardToken.sol";

contract PoolToken is StandardToken {

  string public name;
  string public symbol;
  address public owner;

  uint8 public constant decimals = 18;

  event Burn(address from, uint256 value);

  // Initialize the contract
  constructor(uint256 _initial_supply, string memory _name, string memory _symbol) public {
    totalSupply = _initial_supply;
    balances[msg.sender] = _initial_supply;
    owner = msg.sender;

    name = _name;
    symbol = _symbol;
  }

  // Delete tokens from supply and balance
  function burn(address _from, uint256 _value) public returns (bool) {
    require(msg.sender == owner);
    balances[_from] = balances[_from].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_from, _value);
    return true;
  }

}

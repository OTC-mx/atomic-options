pragma solidity >=0.4.21 <0.6.0;

import "../lib/ERC20.sol";
import "./parent_contracts/IndivisibleCommon.sol";

/**
 * @title SilentOption
 * @dev Option that doesn't reveal strike price until exercised
 */
contract SilentOption is IndivisibleCommon {
  // // Strike price [i.e. (strike_price_quote * base_volume) / strike_price_base  = asset_volume]
  bytes32 public strike_price_base_hash;
  bytes32 public strike_price_quote_hash;

  constructor(address _issuer, address _buyer,
              address _base_addr, address _asset_addr,
              uint256 _fee,
              bytes32 _strike_price_base_hash, bytes32 _strike_price_quote_hash,
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
    strike_price_base_hash = _strike_price_base_hash;
    strike_price_quote_hash = _strike_price_quote_hash;
    volume = _volume;
    maturity_time = _maturity_time;
    expiry_time = _expiry_time;

    base = ERC20(_base_addr);
    asset = ERC20(_asset_addr);

    state = STATE_INITIALIZED;
  }

  /*
  strike_price_base_bytes: bytes32 = convert(strike_price_base, bytes32)
  strike_price_quote_bytes: bytes32 = convert(strike_price_quote, bytes32)
  strike_price_base_hash_claimed: bytes32 = keccak256(concat(strike_price_base_bytes, salt))
  strike_price_quote_hash_claimed: bytes32 = keccak256(concat(strike_price_quote_bytes, salt))
  assert (strike_price_base_hash_claimed == self.strike_price_base_hash)
  assert (strike_price_quote_hash_claimed == self.strike_price_quote_hash)
  */
  function check_hashes(uint256 strike_price_base,
                        uint256 strike_price_quote,
                        bytes32 salt) public view returns (bool) {
    bytes32 strike_price_base_bytes = bytes32(strike_price_base);
    bytes32 strike_price_quote_bytes = bytes32(strike_price_quote);
    bytes32 strike_price_base_hash_claimed = keccak256(abi.encodePacked(strike_price_base_bytes, salt));
    bytes32 strike_price_quote_hash_claimed = keccak256(abi.encodePacked(strike_price_quote_bytes, salt));

    require(strike_price_base_hash_claimed == strike_price_base_hash);
    require(strike_price_quote_hash_claimed == strike_price_quote_hash);

    return true;
  }

  // // Exercise wrappers: can only be called by buyer.
  // Specify how many to buy
  function exercise_from_asset(uint256 asset_volume_exercised,
                                uint256 strike_price_base,
                                uint256 strike_price_quote,
                                bytes32 salt) public {
    require(msg.sender == buyer);

    bool hashes_valid = check_hashes(strike_price_base, strike_price_quote, salt);
    require(hashes_valid);

    uint256 base_volume_exercised = (asset_volume_exercised * strike_price_base) / strike_price_quote;
    exercise_internal(base_volume_exercised, asset_volume_exercised);
  }

  // Specify how many to sell
  function exercise_from_base(uint256 base_volume_exercised,
                                uint256 strike_price_base,
                                uint256 strike_price_quote,
                                bytes32 salt) public {
    assert(msg.sender == buyer);

    bool hashes_valid = check_hashes(strike_price_base, strike_price_quote, salt);
    require(hashes_valid);

    uint256 asset_volume_exercised = (base_volume_exercised * strike_price_quote) / strike_price_base;

    exercise_internal(base_volume_exercised, asset_volume_exercised);
  }

  // Returns all information about the contract in one go
  function get_info() public view returns (address, address, address, address,
                                            uint256, bytes32, bytes32,
                                            uint256, uint256, uint256, uint256) {
    return(issuer, buyer, base_addr, asset_addr,
            fee, strike_price_base_hash, strike_price_quote_hash,
            volume, maturity_time, expiry_time, state);
  }
}

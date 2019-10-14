pragma solidity >=0.4.21 <0.6.0;

import "../../lib/ERC20.sol";
import "../parent_contracts/OptionCommon.sol";
import "../auxiliary/PoolToken.sol";

/**
 * @title TokenizedOption
 * @dev Option where you can trade claims on the collateral and options
 */
contract TokenizedOption is OptionCommon {
  // // Strike price [i.e. (strike_price_quote * base_volume) / strike_price_base  = asset_volume]
  uint256 public strike_price_base;
  uint256 public strike_price_quote;

  // Addresses of the pool tokens
  address public option_claim_addr;
  address public collateral_claim_addr;

  // Number of option/collateral claims outstanding
  uint256 public option_claim_supply;
  uint256 public collateral_claim_supply;

  // Tokens representing a claim on options and collateral, respectively
  PoolToken public option_claim;
  PoolToken public collateral_claim;

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

    option_claim_supply = (_volume * _strike_price_base) / _strike_price_quote;
    collateral_claim_supply = _volume;

    option_claim = new PoolToken(option_claim_supply);
    collateral_claim = new PoolToken(collateral_claim_supply);

    option_claim_addr = address(option_claim);
    collateral_claim_addr = address(collateral_claim);
  }

  function exercise_internal(address exerciser, uint256 base_volume_exercised, uint256 asset_volume_exercised)
      internal {
    require((expiry_time > block.timestamp) && (maturity_time <= block.timestamp));
    require((state == STATE_ACTIVE) || (state == STATE_EXERCISED));
    require(base_volume_exercised > 0);
    require((asset_volume_exercised > 0) && (asset_volume_exercised <= volume));

    bool base_transfer = base.transferFrom(exerciser, address(this), base_volume_exercised);
    require(base_transfer);
    bool option_claim_burn = option_claim.burn(exerciser, base_volume_exercised);
    require(option_claim_burn);
    bool asset_transfer = asset.transfer(buyer, asset_volume_exercised);
    require(asset_transfer);

    option_claim_supply = option_claim.totalSupply();
    volume = volume - asset_volume_exercised;

    state = STATE_EXERCISED;
  }

  // // Exercise wrappers
  // Specify how many to buy
  function exercise_from_asset(uint256 asset_volume_exercised) public {
    uint256 base_volume_exercised = (asset_volume_exercised * strike_price_base) / strike_price_quote;

    require(base_volume_exercised <= option_claim.balanceOf(msg.sender));

    exercise_internal(msg.sender, base_volume_exercised, asset_volume_exercised);
  }

  // Specify how many to sell
  function exercise_from_base(uint256 base_volume_exercised) public {
    require(base_volume_exercised <= option_claim.balanceOf(msg.sender));

    uint256 asset_volume_exercised = (base_volume_exercised * strike_price_quote) / strike_price_base;

    exercise_internal(msg.sender, base_volume_exercised, asset_volume_exercised);
  }

  // // Marks option as expired and refunds claim.
  // Can call either before activation (to abort) or after expiry time
  // OR can call after all options have been exercised
  function expire() public {
    require((expiry_time <= block.timestamp) ||
            (state == STATE_COLLATERALIZED) ||
            (volume == 0));

    uint256 collateral_claim_balance = collateral_claim.balanceOf(msg.sender);
    uint256 asset_claimed = (collateral_claim_balance * volume) / collateral_claim_supply;
    uint256 my_base_balance = base.balanceOf(address(this));
    uint256 base_claimed = (collateral_claim_balance * my_base_balance) / collateral_claim_supply;

    bool collateral_claim_burn = collateral_claim.burn(msg.sender, collateral_claim_balance);
    require(collateral_claim_burn);
    bool base_transfer = base.transfer(msg.sender, base_claimed);
    require(base_transfer);
    bool asset_transfer = asset.transfer(msg.sender, asset_claimed);
    require(asset_transfer);

    state = STATE_EXPIRED;
  }

  // Returns all information about the base contract in one go
  function get_info() public view returns (address, address, address, address,
                                            uint256, uint256, uint256,
                                            uint256, uint256, uint256,
                                            uint256) {
    return(issuer, buyer, base_addr, asset_addr,
            fee, strike_price_base, strike_price_quote,
            volume, maturity_time, expiry_time,
            state);
  }

  // Returns information about the tokens
  function get_token_info() public view returns (address, address, uint256, uint256) {
    return(option_claim_addr, collateral_claim_addr,
            option_claim_supply, collateral_claim_supply);
  }
}

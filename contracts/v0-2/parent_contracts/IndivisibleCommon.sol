pragma solidity >=0.4.21 <0.6.0;

import "./OptionCommon.sol";

/**
 * @title IndivisibleCommon
 * @dev Template for StandardOption, SilentOption
 */
contract IndivisibleCommon is OptionCommon {
  function exercise_internal(uint256 base_volume_exercised,
                              uint256 asset_volume_exercised) internal {
    require((expiry_time > block.timestamp) && (maturity_time <= block.timestamp));
    require((state == STATE_ACTIVE) || (state == STATE_EXERCISED));
    require(base_volume_exercised > 0);
    require((asset_volume_exercised > 0) && (asset_volume_exercised <= volume));

    bool base_transfer = base.transferFrom(buyer, issuer, base_volume_exercised);
    require(base_transfer);
    bool asset_transfer = asset.transfer(buyer, asset_volume_exercised);
    require(asset_transfer);

    volume = volume - asset_volume_exercised;

    state = STATE_EXERCISED;
  }
}

pragma solidity >=0.4.21 <0.6.0;

import "../../lib/ERC20.sol";
import "./Forward.sol";
import "../auxiliary/Portfolio.sol";
import "../factories/ManagedForwardFactory.sol";

/**
 * @title ManagedForward
 * @dev Forward contract managed by Portfolio
 */
contract ManagedForward is Forward {

  address public factory_addr;
  ManagedForwardFactory public factory;

  // // Address of Issuer and Buyer portfolios
  address public issuer_portfolio_addr;
  address public buyer_portfolio_addr;

  // Instances of Issuer and Buyer Portfolios
  Portfolio public issuer_portfolio;
  Portfolio public buyer_portfolio;

  // Unmatched base and asset volumes
  uint256 public unmatched_base_volume;
  uint256 public unmatched_asset_volume;

  // The addresses of the contract this was matched against
  address public asset_matched_addr;
  address public base_matched_addr;

  constructor(address _issuer, address _buyer,
              address _base_addr, address _asset_addr,
              uint256 _strike_price_base, uint256 _strike_price_quote,
              uint256 _volume,
              uint256 _maturity_time,
              address _issuer_portfolio_addr, address _buyer_portfolio_addr)
    Forward(_issuer, _buyer,
              _base_addr, _asset_addr,
              _strike_price_base, _strike_price_quote,
              _volume,
              _maturity_time) public {
    factory_addr = msg.sender;
    factory = ManagedForwardFactory(factory_addr);

    issuer_portfolio_addr = _issuer_portfolio_addr;
    buyer_portfolio_addr = _buyer_portfolio_addr;
    issuer_portfolio = Portfolio(issuer_portfolio_addr);
    buyer_portfolio = Portfolio(buyer_portfolio_addr);
    base_volume = (volume * strike_price_base) / strike_price_quote;

    unmatched_asset_volume = volume;
    unmatched_base_volume = base_volume;
  }

  // // Collateralizes contract
  // Collateralizes from wallet
  function collateralize() public {
    require(msg.sender == issuer);
    require(state == STATE_INITIALIZED);

    bool asset_transfer = asset.transferFrom(issuer, issuer_portfolio_addr, volume);
    require(asset_transfer);

    state = STATE_COLLATERALIZED;
  }

  // Collateralizes from portfolio
  function collateralize_from_portfolio() public {
    require(msg.sender == issuer);
    require(state == STATE_INITIALIZED);

    uint256 asset_available = issuer_portfolio.get_volume_available(asset_addr);
    require(asset_available >= volume);
    issuer_portfolio.set_volume_available(asset_addr, asset_available - volume);

    state = STATE_COLLATERALIZED;
  }

  // Collateralize this forward using the payoff from another forward
  function collateralize_from_match(address _matched_addr) public {
    require(msg.sender == issuer);
    require(factory.get_created_forward(_matched_addr));
    bool match_collateralized = issuer_portfolio.match_collateralize(address(this), _matched_addr);
    require(match_collateralized);
    asset_matched_addr = _matched_addr;
    collateralize_from_portfolio();
  }

  function activate() public {
    require(msg.sender == buyer);
    require(state == STATE_COLLATERALIZED);

    bool base_transfer = base.transferFrom(buyer, buyer_portfolio_addr, base_volume);
    require(base_transfer);

    state = STATE_ACTIVE;
  }

  function activate_from_portfolio() public {
    require(msg.sender == buyer);
    require(state == STATE_COLLATERALIZED);

    uint256 base_available = buyer_portfolio.get_volume_available(base_addr);
    require(base_available >= base_volume);
    buyer_portfolio.set_volume_available(base_addr, base_available - base_volume);

    state = STATE_ACTIVE;
  }

  function activate_from_match(address _matched_addr) public {
    require(msg.sender == buyer);
    require(factory.get_created_forward(_matched_addr));
    bool match_activated = buyer_portfolio.match_activate(address(this), _matched_addr);
    require(match_activated);
    base_matched_addr = _matched_addr;
    activate_from_portfolio();
  }

  // Executes the forward trade
  function settle() public {
    require(maturity_time <= block.timestamp);
    require(volume > 0);

    bool issuer_approve = issuer_portfolio.approve_managed_forward(asset_addr, volume);
    require(issuer_approve);
    bool buyer_approve = buyer_portfolio.approve_managed_forward(base_addr, base_volume);
    require(buyer_approve);
    bool asset_transfer = asset.transferFrom(issuer_portfolio_addr, buyer_portfolio_addr, volume);
    require(asset_transfer);
    bool base_transfer = base.transferFrom(buyer_portfolio_addr, issuer_portfolio_addr, base_volume);
    require(base_transfer);

    uint256 portfolio_base_available = issuer_portfolio.get_volume_available(base_addr);
    issuer_portfolio.set_volume_available(base_addr, portfolio_base_available + unmatched_base_volume);
    uint256 portfolio_asset_available = buyer_portfolio.get_volume_available(asset_addr);
    buyer_portfolio.set_volume_available(asset_addr, portfolio_asset_available + unmatched_asset_volume);

    volume = 0;
    base_volume = 0;
    unmatched_asset_volume = 0;
    unmatched_base_volume = 0;

    state = STATE_EXPIRED;
  }

  // Internal logic for force_settle
  function force_settle_internal(address matched_addr) internal returns (bool) {
    ManagedForward matched = ManagedForward(matched_addr);
    if (matched.state() != STATE_EXPIRED) {
      matched.force_settle();
    }
    return true;
  }

  // Settles every dependency until this contract can settle
  // Basically a depth-first-search to settle the contract
  function force_settle() public returns (bool) {
    force_settle_internal(base_matched_addr);
    force_settle_internal(asset_matched_addr);
    settle();
    return true;
  }

  // In a forward, only really useful for aborting
  // Conditions and call mostly kept consistent with OptionCommon
  function expire() public {
    require(msg.sender == issuer);
    require(state == STATE_COLLATERALIZED);
    require(state != STATE_EXPIRED);

    bool asset_transfer = asset.transfer(issuer_portfolio_addr, volume);
    require(asset_transfer);
    uint256 portfolio_asset_available = issuer_portfolio.get_volume_available(asset_addr);
    issuer_portfolio.set_volume_available(asset_addr, portfolio_asset_available + volume);

    state = STATE_EXPIRED;
  }

  function set_unmatched_base_volume(uint value) public {
    require(msg.sender == issuer_portfolio_addr);
    unmatched_base_volume = value;
  }

  function set_unmatched_asset_volume(uint value) public {
    require(msg.sender == buyer_portfolio_addr);
    unmatched_asset_volume = value;
  }

  // Returns all portfolio information in one go
  function get_portfolio_info() public view returns (address, address,
                                                      uint256, uint256,
                                                      address, address) {
    return(issuer_portfolio_addr, buyer_portfolio_addr,
            unmatched_base_volume, unmatched_asset_volume,
            asset_matched_addr, base_matched_addr);
  }
}

pragma solidity >=0.4.21 <0.6.0;

import "../forwards/ManagedForward.sol";
import "../factories/ManagedForwardFactory.sol";

contract Portfolio {

  // The two tokens this portfolio matches trades on
  address public base_addr;
  address public asset_addr;

  // Information on owner and where this portfolio's forwards are minted
  address public owner;
  address public managed_forward_factory_addr;
  ManagedForwardFactory public managed_forward_factory;

  // Map stores indices, list stores the actual forwards
  mapping(address => uint256) public my_forward_indices;
  address[] public my_forwards;

  // How much volume of each token is available?
  mapping(address => uint256) public volume_available;

  constructor(address _base_addr, address _asset_addr,
              address _owner, address _managed_forward_factory_addr) public {
    require(_base_addr != _asset_addr);
    base_addr = _base_addr;
    asset_addr = _asset_addr;

    owner = _owner;
    managed_forward_factory_addr = _managed_forward_factory_addr;
    managed_forward_factory = ManagedForwardFactory(managed_forward_factory_addr);
    my_forwards.push(address(0));
  }

  function add_managed_forward(address managed_forward_addr) public {
    require(msg.sender == owner);

    bool is_from_factory = managed_forward_factory.get_created_forward(managed_forward_addr);
    require(is_from_factory);

    ManagedForward managed_forward = ManagedForward(managed_forward_addr);
    bool owner_party = ((owner == managed_forward.issuer()) || (owner == managed_forward.buyer()));
    bool portfolio_party = ((address(this) == managed_forward.issuer_portfolio_addr()) ||
                            (address(this) == managed_forward.buyer_portfolio_addr()));
    require(owner_party && portfolio_party);

    address fwd_base_addr = managed_forward.base_addr();
    address fwd_asset_addr = managed_forward.asset_addr();
    bool my_base_traded = (base_addr == fwd_base_addr) || (base_addr == fwd_asset_addr);
    bool my_asset_traded = (asset_addr == fwd_base_addr) || (asset_addr == fwd_asset_addr);
    require(my_base_traded && my_asset_traded && (fwd_base_addr != fwd_asset_addr));

    uint index = my_forwards.push(managed_forward_addr) - 1;
    my_forward_indices[managed_forward_addr] = index;
  }

  function approve_managed_forward(address token_addr, uint256 value) public returns (bool) {
    require(token_addr == base_addr || token_addr == asset_addr);
    require(my_forward_indices[msg.sender] > 0);
    bool approve_call = ERC20(token_addr).approve(msg.sender, value);
    require(approve_call);
    return true;
  }

  function set_volume_available(address token_addr, uint256 value) public {
    require(my_forward_indices[msg.sender] > 0);
    volume_available[token_addr] = value;
  }

  // // NOTE: Under new architecture, can't just match retroactively.

  // old_fwd is already active, and pays out at the same time as or before new_fwd does, in new_fwd's asset currency
  function match_collateralize(address new_fwd_addr, address old_fwd_addr) public returns (bool) {
    require(my_forward_indices[msg.sender] > 0);
    require((my_forward_indices[new_fwd_addr] > 0) && (my_forward_indices[old_fwd_addr] > 0));

    ManagedForward new_fwd = ManagedForward(new_fwd_addr);
    ManagedForward old_fwd = ManagedForward(old_fwd_addr);
    // new_fwd is being collateralized
    require(new_fwd.state() == new_fwd.STATE_INITIALIZED());
    // old_fwd is already active
    require(old_fwd.state() == old_fwd.STATE_ACTIVE());
    // and pays out at the same time as or before new_fwd does
    require(old_fwd.maturity_time() <= new_fwd.maturity_time());
    // in new_fwd's asset currency
    address new_asset = new_fwd.asset_addr();
    bool base_to_asset = ((owner == old_fwd.issuer()) && (old_fwd.base_addr() == new_asset));
    bool asset_to_asset = ((owner == old_fwd.buyer()) && (old_fwd.asset_addr() == new_asset));
    require(base_to_asset || asset_to_asset);

    // Credit you in advance with old_fwd's payout, up to a limit of new_fwd's volume
    uint256 old_unmatched = (base_to_asset ?
                            old_fwd.unmatched_base_volume() :
                            old_fwd.unmatched_asset_volume());
    uint256 new_volume = new_fwd.volume();
    uint256 additional_credit = (new_volume > old_unmatched ?
                                              old_unmatched :
                                              new_volume);
    volume_available[new_fwd.asset_addr()] += additional_credit;

    // Update the old_fwd unmatched volume
    if (base_to_asset) {
      old_fwd.set_unmatched_base_volume(old_unmatched - additional_credit);
    } else {
      old_fwd.set_unmatched_asset_volume(old_unmatched - additional_credit);
    }

   return true;
  }

  // old_fwd is already active, and pays out at the same time as or before new_fwd does, in new_fwd's base currency
  function match_activate(address new_fwd_addr, address old_fwd_addr) public returns (bool) {
    require(my_forward_indices[msg.sender] > 0);
    require((my_forward_indices[new_fwd_addr] > 0) && (my_forward_indices[old_fwd_addr] > 0));

    ManagedForward new_fwd = ManagedForward(new_fwd_addr);
    ManagedForward old_fwd = ManagedForward(old_fwd_addr);
    // new_fwd is being activated
    require(new_fwd.state() == new_fwd.STATE_COLLATERALIZED());
    // old_fwd is already active
    require(old_fwd.state() == old_fwd.STATE_ACTIVE());
    // and pays out at the same time as or before new_fwd does
    require(old_fwd.maturity_time() <= new_fwd.maturity_time());
    // in new_fwd's base currency
    address new_base = new_fwd.base_addr();
    bool base_to_base = ((owner == old_fwd.issuer()) && (old_fwd.base_addr() == new_base));
    bool asset_to_base = ((owner == old_fwd.buyer()) && (old_fwd.asset_addr() == new_base));
    require(base_to_base || asset_to_base);

    // Credit you in advance with old_fwd's payout, up to a limit of new_fwd's base_volume
    uint256 old_unmatched = (base_to_base ?
                            old_fwd.unmatched_base_volume() :
                            old_fwd.unmatched_asset_volume());
    uint256 new_volume = new_fwd.base_volume();
    uint256 additional_credit = (new_volume > old_unmatched ?
                                              old_unmatched :
                                              new_volume);
    volume_available[new_fwd.base_addr()] += additional_credit;
  }

  // Deposit a token into this Portfolio
  function deposit(address token_addr, uint256 value) public {
    require(msg.sender == owner);
    require((token_addr == base_addr) || (token_addr == asset_addr));
    bool token_transfer = ERC20(token_addr).transferFrom(owner, address(this), value);
    require(token_transfer);
    volume_available[token_addr] = volume_available[token_addr] + value;
  }

  // Withdraw a token from this Portfolio
  function withdraw(address token_addr, uint256 value) public {
    require(msg.sender == owner);
    require(volume_available[token_addr] >= value);
    bool token_transfer = ERC20(token_addr).transfer(owner, value);
    require(token_transfer);
    volume_available[token_addr] = volume_available[token_addr] - value;
  }

  function get_volume_available(address token_addr) public view returns (uint256) {
    return volume_available[token_addr];
  }

  function get_forward_index(address forward_address) public view returns (uint256) {
    return my_forward_indices[forward_address];
  }
}

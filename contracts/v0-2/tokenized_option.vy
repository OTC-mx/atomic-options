from vyper.interfaces import ERC20

contract PoolToken:
  def totalSupply() -> uint256: constant
  def balanceOf(_owner: address) -> uint256: constant
  def setup(_initial_supply: uint256): modifying
  def transfer(_to: address, _value:uint256) -> bool: modifying
  def burn(_from: address, _value: uint256) -> bool: modifying

### Basic information
# Buyer and issuer of the option
issuer: public(address)
buyer: public(address)
# Address of the base (that you pay), asset (being bought)
base_addr: public(address)
asset_addr: public(address)

### Financial information
# Fee
fee: public(uint256)
# Strike price [i.e. (strike_price_quote * base_volume) / strike_price_base  = asset_volume]
strike_price_base: public(uint256)
strike_price_quote: public(uint256)
volume: public(uint256)
# Option can be exercised between maturity_time and expiry_time
maturity_time: public(timestamp)
expiry_time: public(timestamp)

### External contracts
# Callable base and asset ERC20s
base: ERC20
asset: ERC20

### Tokenizable Option variables
# Pool token template
token_template: public(address)

# Address of the pool tokens
option_claim_addr: public(address)
collateral_claim_addr: public(address)

# Number of option/collateral claims outstanding
option_claim_supply: public(uint256)
collateral_claim_supply: public(uint256)

# Tokens representing a claim on options and collateral, respectively
option_claim: PoolToken
collateral_claim: PoolToken

### Contract states
state: public(uint256)
STATE_UNINITIALIZED: constant(uint256) = 0
STATE_INITIALIZED: constant(uint256) = 1
STATE_COLLATERALIZED: constant(uint256) = 2
STATE_ACTIVE: constant(uint256) = 3
STATE_EXERCISED: constant(uint256) = 4
STATE_EXPIRED: constant(uint256) = 5

@public
def setup(_issuer: address, _buyer: address,
          _base_addr: address, _asset_addr: address,
          _fee: uint256, _strike_price_base: uint256, _strike_price_quote: uint256,
          _volume: uint256,
          _maturity_time: timestamp, _expiry_time: timestamp,
          _token_template: address):
    assert (self.state == STATE_UNINITIALIZED)
    assert (_base_addr != _asset_addr)
    assert (_expiry_time > block.timestamp) and (_expiry_time > _maturity_time)

    # Standard Option Variables
    self.issuer = _issuer
    self.buyer = _buyer
    self.base_addr = _base_addr
    self.asset_addr = _asset_addr
    self.fee = _fee
    self.strike_price_base = _strike_price_base
    self.strike_price_quote = _strike_price_quote
    self.volume = _volume
    self.maturity_time = _maturity_time
    self.expiry_time = _expiry_time

    self.base = ERC20(_base_addr)
    self.asset = ERC20(_asset_addr)

    # Tokenizable Option Variables
    self.token_template = _token_template
    self.option_claim_supply = (_volume * _strike_price_base) / _strike_price_quote
    self.collateral_claim_supply = _volume
    self.option_claim_addr = create_forwarder_to(_token_template)
    self.option_claim = PoolToken(self.option_claim_addr)
    self.option_claim.setup(self.option_claim_supply)
    self.collateral_claim_addr = create_forwarder_to(_token_template)
    self.collateral_claim = PoolToken(self.collateral_claim_addr)
    self.collateral_claim.setup(self.collateral_claim_supply)

    # Update State
    self.state = STATE_INITIALIZED

## Collateralizes option
@public
def collateralize():
    assert (msg.sender == self.issuer)
    assert (self.state == STATE_INITIALIZED)
    assert (self.expiry_time > block.timestamp)

    asset_transfer: bool = self.asset.transferFrom(self.issuer, self, self.volume)
    assert asset_transfer
    collateral_claim_transfer: bool = self.collateral_claim.transfer(self.issuer, self.volume)
    assert collateral_claim_transfer

    self.state = STATE_COLLATERALIZED

## Pays fee to issuer
@public
def pay_fee():
    assert (msg.sender == self.buyer)
    assert (self.state == STATE_COLLATERALIZED)
    assert (self.expiry_time > block.timestamp)

    base_transfer: bool = self.base.transferFrom(self.buyer, self.issuer, self.fee)
    assert base_transfer
    option_claim_transfer: bool = self.option_claim.transfer(self.buyer, self.option_claim_supply)
    assert option_claim_transfer

    self.state = STATE_ACTIVE

## Exercises the option and refunds the issuer for unused volume.
# Internal function for core logic
@private
def exercise_internal(exerciser: address, base_volume_exercised: uint256, asset_volume_exercised: uint256):
    assert (self.expiry_time > block.timestamp) and (self.maturity_time <= block.timestamp)
    assert (self.state == STATE_ACTIVE) or (self.state == STATE_EXERCISED)
    assert (base_volume_exercised > 0)
    assert (asset_volume_exercised > 0) and (asset_volume_exercised <= self.volume)

    base_transfer: bool = self.base.transferFrom(exerciser, self, base_volume_exercised)
    assert base_transfer
    option_claim_burn: bool = self.option_claim.burn(exerciser, base_volume_exercised)
    assert option_claim_burn
    asset_transfer: bool = self.asset.transfer(self.buyer, asset_volume_exercised)
    assert asset_transfer

    self.option_claim_supply = self.option_claim.totalSupply()
    self.volume = self.volume - asset_volume_exercised

    self.state = STATE_EXERCISED

## Exercise wrappers: can only be called by buyer.
# Specify how many to buy
@public
def exercise_from_asset(asset_volume_exercised: uint256):
    base_volume_exercised: uint256 = (asset_volume_exercised * self.strike_price_base) / self.strike_price_quote

    self.exercise_internal(msg.sender, base_volume_exercised, asset_volume_exercised)


# Specify how many to sell
@public
def exercise_from_base(base_volume_exercised: uint256):
    asset_volume_exercised: uint256 = (base_volume_exercised * self.strike_price_quote) / self.strike_price_base

    self.exercise_internal(msg.sender, base_volume_exercised, asset_volume_exercised)

## Marks option as expired and refunds issuer.
# Can call either before activation (to abort) or after expiry time
# OR can call after all options have been exercised
@public
def expire():
    assert (self.expiry_time <= block.timestamp) or (self.state == STATE_COLLATERALIZED) or (self.volume == 0)

    sender_collateral_claim_balance: uint256 = self.collateral_claim.balanceOf(msg.sender)
    asset_claimed: uint256 = (sender_collateral_claim_balance * self.volume) / self.collateral_claim_supply
    my_base_balance: uint256 = self.base.balanceOf(self)
    base_claimed: uint256 = (sender_collateral_claim_balance * my_base_balance) / self.collateral_claim_supply

    collateral_claim_burn: bool = self.collateral_claim.burn(msg.sender, sender_collateral_claim_balance)
    assert collateral_claim_burn
    base_transfer: bool = self.base.transfer(msg.sender, base_claimed)
    assert base_transfer
    asset_transfer: bool = self.asset.transfer(msg.sender, asset_claimed)
    assert asset_transfer

    self.state = STATE_EXPIRED

# Returns all information about the contract in one go
@public
@constant
def get_info() -> (address, address, address, address,
                    uint256, uint256, uint256,
                    uint256, timestamp, timestamp,
                    address, address, address,
                    uint256, uint256,
                    uint256):
    return (self.issuer, self.buyer, self.base_addr, self.asset_addr,
            self.fee, self.strike_price_base, self.strike_price_quote,
            self.volume, self.maturity_time, self.expiry_time,
            self.token_template, self.option_claim_addr, self.collateral_claim_addr,
            self.option_claim_supply, self.collateral_claim_supply,
            self.state)

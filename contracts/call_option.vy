from vyper.interfaces import ERC20

## Basic information
# Buyer and issuer of the option
issuer: public(address)
buyer: public(address)
# Address of the base (that you pay), asset (being bought)
base_addr: public(address)
asset_addr: public(address)

## Financial information
# Fee
fee: public(uint256)
# Strike price [i.e. (strike_price_base * base_volume) / strike_price_quote = asset_volume]
strike_price_base: public(uint256)
strike_price_quote: public(uint256)
volume: public(uint256)
# Option can be exercised between maturity_time and expiry_time
maturity_time: public(timestamp)
expiry_time: public(timestamp)

## Contract states
state: public(uint256)
STATE_UNINITIALIZED: constant(uint256) = 0
STATE_INITIALIZED: constant(uint256) = 1
STATE_COLLATERALIZED: constant(uint256) = 2
STATE_ACTIVE: constant(uint256) = 3
STATE_EXERCISED: constant(uint256) = 4
STATE_EXPIRED: constant(uint256) = 5

## External contracts
# Callable base and asset ERC20s
base: ERC20
asset: ERC20

@public
def setup(_issuer: address, _buyer: address,
          _base_addr: address, _asset_addr: address,
          _fee: uint256, _strike_price_base: uint256, _strike_price_quote: uint256,
          _volume: uint256,
          _maturity_time: timestamp, _expiry_time: timestamp):
    assert (self.state == STATE_UNINITIALIZED)
    assert (_base_addr != _asset_addr)
    assert (_expiry_time > block.timestamp) and (_expiry_time > _maturity_time)

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

    self.state = STATE_INITIALIZED

## Collateralizes option
@public
def collateralize():
    assert (msg.sender == self.issuer)
    assert (self.state == STATE_INITIALIZED)
    assert (self.expiry_time > block.timestamp)

    asset_transfer: bool = self.asset.transferFrom(self.issuer, self, self.volume)
    assert asset_transfer

    self.state = STATE_COLLATERALIZED

## Pays fee to issuer
@public
def pay_fee():
    assert (msg.sender == self.buyer)
    assert (self.state == STATE_COLLATERALIZED)
    assert (self.expiry_time > block.timestamp)

    base_transfer: bool = self.base.transferFrom(self.buyer, self.issuer, self.fee)
    assert base_transfer

    self.state = STATE_ACTIVE

## Exercises the option and refunds the issuer for unused volume.
# Internal function for core logic
@private
def exercise_internal(base_volume_exercised: uint256, asset_volume_exercised: uint256):
    assert (self.expiry_time > block.timestamp) and (self.maturity_time <= block.timestamp)
    assert (self.state == STATE_ACTIVE) or (self.state == STATE_EXERCISED)
    assert (base_volume_exercised > 0)
    assert (asset_volume_exercised > 0) and (asset_volume_exercised <= self.volume)

    base_transfer: bool = self.base.transferFrom(self.buyer, self.issuer, base_volume_exercised)
    assert base_transfer
    asset_transfer: bool = self.asset.transferFrom(self.issuer, self.buyer, asset_volume_exercised)
    assert asset_transfer

    self.volume = self.volume - asset_volume_exercised

    self.state = STATE_EXERCISED

## Exercise wrappers: can only be called by buyer.
# Specify how many to buy
@public
def exercise_from_asset(asset_volume_exercised: uint256):
    assert (msg.sender == self.buyer)

    base_volume_exercised: uint256 = (asset_volume_exercised * self.strike_price_quote) / self.strike_price_base

    self.exercise_internal(base_volume_exercised, asset_volume_exercised)


# Specify how many to sell
@public
def exercise_from_base(base_volume_exercised: uint256):
    assert (msg.sender == self.buyer)

    asset_volume_exercised: uint256 = (base_volume_exercised * self.strike_price_base) / self.strike_price_quote

    self.exercise_internal(base_volume_exercised, asset_volume_exercised)

## Marks option as expired and refunds issuer.
# Can call either before activation (to abort) or after exipry time
# Can only be called by issuer
@public
def expire():
    assert (msg.sender == self.buyer) or (msg.sender == self.issuer)
    assert (self.expiry_time <= block.timestamp) or (self.state == STATE_COLLATERALIZED)
    assert (self.state != STATE_EXPIRED)
    asset_balance: uint256 = self.asset.balanceOf(self)
    self.asset.transfer(self.issuer, asset_balance)

    self.state = STATE_EXPIRED

## Excess withdrawal functions
# Allow buyer/issuer to withdraw excess base/asset

# Can only be called by buyer
@public
def withdraw_excess_base(amount: uint256):
    assert (msg.sender == self.buyer)
    base_balance: uint256 = self.base.balanceOf(self)
    assert (base_balance >= amount) and (amount >= 0)
    self.asset.transfer(self.buyer, amount)

# Can only be called by issuer
@public
def withdraw_excess_asset(amount: uint256):
    assert (msg.sender == self.issuer)
    asset_balance: uint256 = self.asset.balanceOf(self)
    assert (asset_balance >= amount + self.volume) and (amount >= 0)
    self.asset.transfer(self.issuer, amount)

# Returns all information about the contract in one go
@public
@constant
def get_info() -> (address, address, address, address,
                    uint256, uint256, uint256,
                    uint256, timestamp, timestamp, uint256):
    return (self.issuer, self.buyer, self.base_addr, self.asset_addr,
            self.fee, self.strike_price_base, self.strike_price_quote,
            self.volume, self.maturity_time, self.expiry_time, self.state)

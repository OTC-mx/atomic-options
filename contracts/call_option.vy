from vyper.interfaces import ERC20

## Basic information
# Buyer and issuer of the option
issuer: address
buyer: address
# Address of the base (that you pay), asset (being bought)
base_addr: address
asset_addr: address

## Financial information
# Fee and strike price (in base), volume (of asset)
fee: uint256
strike_price: uint256
volume: uint256
# Option can be exercised between maturity_time and expiry_time
maturity_time: timestamp
expiry_time: timestamp

## Contract states
state: uint256
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
          _fee: uint256, _strike_price: uint256, _volume: uint256,
          _maturity_time: timestamp, _expiry_time: timestamp):
    assert (self.state == STATE_UNINITIALIZED)
    assert (_base_addr != _asset_addr)
    assert (_expiry_time > block.timestamp)

    self.issuer = _issuer
    self.buyer = _buyer
    self.base_addr = _base_addr
    self.asset_addr = _asset_addr
    self.fee = _fee
    self.strike_price = _strike_price
    self.volume = _volume
    self.maturity_time = _maturity_time
    self.expiry_time = _expiry_time

    self.base = ERC20(_base_addr)
    self.asset = ERC20(_asset_addr)

    self.state = STATE_INITIALIZED

## Checks that option has been collateralized by issuer
@public
def check_collateralization():
    assert (self.state == STATE_INITIALIZED)
    assert (self.expiry_time > block.timestamp)
    asset_balance: uint256 = self.asset.balanceOf(self)
    assert (asset_balance >= self.volume)
    if asset_balance > self.volume:
        self.asset.transfer(self.issuer, asset_balance - self.volume)

    self.state = STATE_COLLATERALIZED

## Checks that fee has been paid, relays to issuer
@public
def relay_fee():
    assert (self.state == STATE_COLLATERALIZED)
    assert (self.expiry_time > block.timestamp)
    base_balance: uint256 =  self.base.balanceOf(self)
    assert (base_balance >= self.fee)
    self.base.transfer(self.issuer, self.fee)
    if base_balance > self.fee:
        self.base.transfer(self.buyer, base_balance - self.fee)

    self.state = STATE_ACTIVE

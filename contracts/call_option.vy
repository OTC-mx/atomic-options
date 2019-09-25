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

## Contract states
state: uint256
STATE_UNINITIALIZED: constant(uint256) = 0
STATE_INITIALIZED: constant(uint256) = 1
STATE_COLLATERALIZED: constant(uint256) = 2
STATE_ACTIVE: constant(uint256) = 3
STATE_EXERCISED: constant(uint256) = 4
STATE_EXPIRED: constant(uint256) = 5

@public
def init(_issuer: address, _buyer: address,
          _base_addr: address, _asset_addr: address,
          _fee: uint256, _strike_price: uint256, _volume: uint256):
    assert (self.state == STATE_UNINITIALIZED)
    self.issuer = _issuer
    self.buyer = _buyer
    self.base_addr = _base_addr
    self.asset_addr = _asset_addr
    self.fee = _fee
    self.strike_price = _strike_price
    self.volume = _volume
    self.state = STATE_INITIALIZED

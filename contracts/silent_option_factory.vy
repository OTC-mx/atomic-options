contract Option():
    def setup(_issuer: address, _buyer: address,
              _base_addr: address, _asset_addr: address,
              _fee: uint256, _strike_price_base_hash: bytes32, _strike_price_quote_hash: bytes32,
              _volume: uint256,
              _maturity_time: timestamp, _expiry_time: timestamp): modifying

Initialized: event({template: address})
NewOption: event({option: address})

template: public(address)

@public
def initializeFactory(_template: address):
    assert self.template == ZERO_ADDRESS
    self.template = _template

@public
def createOption(_issuer: address, _buyer: address,
                _base_addr: address, _asset_addr: address,
                _fee: uint256, _strike_price_base_hash: bytes32, _strike_price_quote_hash: bytes32,
                _volume: uint256,
                _maturity_time: timestamp, _expiry_time: timestamp) -> address:
    option: address = create_forwarder_to(self.template)
    Option(option).setup(_issuer, _buyer,
                        _base_addr, _asset_addr,
                        _fee, _strike_price_base_hash, _strike_price_quote_hash,
                        _volume, _maturity_time, _expiry_time)
    log.NewOption(option)
    return option

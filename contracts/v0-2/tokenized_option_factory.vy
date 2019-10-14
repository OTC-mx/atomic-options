contract TokenizedOption():
    def setup(_issuer: address, _buyer: address,
              _base_addr: address, _asset_addr: address,
              _fee: uint256, _strike_price_base: uint256, _strike_price_quote: uint256,
              _volume: uint256,
              _maturity_time: timestamp, _expiry_time: timestamp,
              _token_template: address): modifying

Initialized: event({template: address, token_template: address})
NewTokenizedOption: event({tokenized_option: address})

template: public(address)
token_template: public(address)

@public
def initializeFactory(_template: address, _token_template: address):
    assert self.template == ZERO_ADDRESS
    self.template = _template
    assert self.token_template == ZERO_ADDRESS
    self.token_template = _token_template

@public
def createOption(_issuer: address, _buyer: address,
                _base_addr: address, _asset_addr: address,
                _fee: uint256, _strike_price_base: uint256, _strike_price_quote: uint256,
                _volume: uint256,
                _maturity_time: timestamp, _expiry_time: timestamp) -> address:
    tokenized_option: address = create_forwarder_to(self.template)
    TokenizedOption(tokenized_option).setup(_issuer, _buyer,
                                            _base_addr, _asset_addr,
                                            _fee, _strike_price_base, _strike_price_quote,
                                            _volume, _maturity_time, _expiry_time,
                                            self.token_template)
    log.NewTokenizedOption(tokenized_option)
    return tokenized_option

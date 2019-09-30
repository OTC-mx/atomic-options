const CallOption = artifacts.require("call_option");
const OptionFactory = artifacts.require("option_factory");
const TokenA = artifacts.require("TokenA");
const TokenB = artifacts.require("TokenB");

contract("1st OptionFactory test suite", async accounts => {
  // Variables consistent with createOption
  let issuer;
  let buyer;
  let base_addr;
  let asset_addr;
  let fee;
  let strike_price_base;
  let strike_price_quote;
  let volume;
  let maturity_time;
  let expiry_time;

  // Non-template option address
  let option_address;

  it("should update template", async () => {
    let call_option_template = await CallOption.deployed();
    let option_factory = await OptionFactory.deployed();

    // Initialize the option factory
    let initialize_call = await (option_factory
      .initializeFactory(call_option_template.address, { from: accounts[0] }));
    let template_value = await option_factory.template();

    assert.equal(template_value, call_option_template.address);
  });

  it("should create CallOption contract", async () => {
    let option_factory = await OptionFactory.deployed();
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();

    // Variables consistent with createOption
    issuer = accounts[0];
    buyer = accounts[1];
    base_addr = token_b.address;
    asset_addr = token_a.address;
    fee = '1' + ('0'.repeat(21));
    strike_price_base = 3;
    strike_price_quote = 5;
    volume = '5' + ('0'.repeat(21));
    maturity_time = '0';
    expiry_time = '1577836800';

    let create_option_call = await (option_factory
      .createOption(issuer, buyer,
        base_addr, asset_addr,
        fee, strike_price_base, strike_price_quote,
        volume,
        maturity_time, expiry_time,
        { from: accounts[0] })
    );
    option_address = create_option_call.logs[0].args[0];

    assert.equal(Boolean(option_address), true);
  });

  it("should output contract with correct variables", async () => {
    // Variables consistent with createOption
    let call_option = new web3.eth.Contract(CallOption.abi, option_address);
    let issuer_observed = await call_option.methods.issuer().call();
    let buyer_observed = await call_option.methods.buyer().call();
    let base_addr_observed = await call_option.methods.base_addr().call();
    let asset_addr_observed = await call_option.methods.asset_addr().call();
    let fee_observed = await call_option.methods.fee().call();
    let strike_price_base_observed = await call_option.methods.strike_price_base().call();
    let strike_price_quote_observed = await await call_option.methods.strike_price_quote().call();
    let volume_observed = await call_option.methods.volume().call();
    let maturity_time_observed = await call_option.methods.maturity_time().call();
    let expiry_time_observed = await call_option.methods.expiry_time().call();

    let expected = [issuer, buyer, base_addr, asset_addr, fee,
      strike_price_base, strike_price_quote, volume, maturity_time, expiry_time]

    let observed = [issuer_observed, buyer_observed, base_addr_observed,
      asset_addr_observed, fee_observed, strike_price_base_observed,
      strike_price_quote_observed, volume_observed,
      maturity_time_observed, expiry_time_observed]

    for (var i = 0; i < expected.length; i++) {
      assert.equal(expected[i], observed[i]);
    }
  });

});
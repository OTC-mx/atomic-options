const Option = artifacts.require("option");
const OptionFactory = artifacts.require("option_factory");
const TokenA = artifacts.require("TokenA");
const TokenB = artifacts.require("TokenB");

const common = require("./common.js")

contract("OptionFactory/Option test suite", async accounts => {
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

  // Non-template option
  let option;
  let option_address;

  it("should update template", async () => {
    let option_template = await Option.deployed();
    let option_factory = await OptionFactory.deployed();
    console.log("Option Factory Address:", option_factory.address);

    // Initialize the option factory
    let initialize_call = await (option_factory
      .initializeFactory(option_template.address, { from: accounts[0] }));
    let template_value = await option_factory.template();
    assert.equal(template_value, option_template.address);
  });

  it("should create Option contract", async () => {
    let option_factory = await OptionFactory.deployed();
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();
    console.log("Base Token Address:", token_b.address);
    console.log("Asset Token Address:", token_a.address);

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
    console.log("Address of Option Created:", option_address);

    assert.equal(Boolean(option_address), true);
  });

  it("should output contract with correct variables", async () => {
    // Variables consistent with createOption
    option = new web3.eth.Contract(Option.abi, option_address);
    let issuer_observed = await option.methods.issuer().call();
    let buyer_observed = await option.methods.buyer().call();
    let base_addr_observed = await option.methods.base_addr().call();
    let asset_addr_observed = await option.methods.asset_addr().call();
    let fee_observed = await option.methods.fee().call();
    let strike_price_base_observed = await option.methods.strike_price_base().call();
    let strike_price_quote_observed = await option.methods.strike_price_quote().call();
    let volume_observed = await option.methods.volume().call();
    let maturity_time_observed = await option.methods.maturity_time().call();
    let expiry_time_observed = await option.methods.expiry_time().call();
    let state_observed = await option.methods.state().call();

    let info_observed = await option.methods.get_info().call();

    let expected = [issuer, buyer, base_addr, asset_addr, fee,
      strike_price_base, strike_price_quote, volume, maturity_time, expiry_time,
      common.state_vals.initialized]

    let observed = [issuer_observed, buyer_observed, base_addr_observed,
      asset_addr_observed, fee_observed, strike_price_base_observed,
      strike_price_quote_observed, volume_observed,
      maturity_time_observed, expiry_time_observed,
      state_observed]

    for (var i = 0; i < expected.length; i++) {
      assert.equal(expected[i], observed[i]);
      assert.equal(expected[i], info_observed[i]);
    }
  });

  it("should output a collateralizable option", async () => {
    let token_a = await TokenA.deployed();

    let approve_call = await token_a.approve(option_address, volume, { from: accounts[0] });
    let collateralize_call = await (
      option
      .methods
      .collateralize()
      .send({ from: accounts[0] })
    );

    let info_observed = await option.methods.get_info().call();
    let asset_balance_observed = await token_a.balanceOf(option_address);
    assert.equal(asset_balance_observed, volume)
    assert.equal(info_observed[10], common.state_vals.collateralized)
  });
});

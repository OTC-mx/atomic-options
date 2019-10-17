const Forward = artifacts.require("Forward");
const ForwardFactory = artifacts.require("ForwardFactory");
const TokenA = artifacts.require("TokenA");
const TokenB = artifacts.require("TokenB");

const common = require("./common.js");

contract("ForwardFactory/Forward test suite", async accounts => {
  // Variables consistent with create_forward
  let issuer;
  let buyer;
  let base_addr;
  let asset_addr;
  let strike_price_base;
  let strike_price_quote;
  let volume;
  let maturity_time;

  // Forward
  let forward;
  let forward_address;

  it("should create Forward contract", async () => {
    let forward_factory = await ForwardFactory.deployed();
    console.log("Forward Factory Address", forward_factory.address);
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();
    console.log("Base Token Address:", token_b.address);
    console.log("Asset Token Address:", token_a.address);

    // Variables consistent with create_forward
    issuer = accounts[0];
    buyer = accounts[1];
    base_addr = token_b.address;
    asset_addr = token_a.address;
    strike_price_base = 3;
    strike_price_quote = 5;
    volume = '5' + ('0'.repeat(21));
    maturity_time = '0';

    let create_forward_call = await (forward_factory
      .create_forward(issuer, buyer,
        base_addr, asset_addr,
        strike_price_base, strike_price_quote,
        volume,
        maturity_time,
        { from: accounts[0] })
    );
    forward_address = create_forward_call.logs[0].args[0];
    console.log("Address of Forward Created:", forward_address);

    assert.equal(Boolean(forward_address), true);
  });

  it("should output contract with correct variables", async () => {
    // Variables consistent with create_forward
    forward = new web3.eth.Contract(Forward.abi, forward_address);
    let issuer_observed = await forward.methods.issuer().call();
    let buyer_observed = await forward.methods.buyer().call();
    let base_addr_observed = await forward.methods.base_addr().call();
    let asset_addr_observed = await forward.methods.asset_addr().call();
    let strike_price_base_observed = await forward.methods.strike_price_base().call();
    let strike_price_quote_observed = await forward.methods.strike_price_quote().call();
    let volume_observed = await forward.methods.volume().call();
    let maturity_time_observed = await forward.methods.maturity_time().call();
    let state_observed = await forward.methods.state().call();

    let info_observed = await forward.methods.get_info().call();

    let expected = [issuer, buyer, base_addr, asset_addr,
      strike_price_base, strike_price_quote, volume, maturity_time,
      common.state_vals.initialized];

    let observed = [issuer_observed, buyer_observed, base_addr_observed,
      asset_addr_observed, strike_price_base_observed,
      strike_price_quote_observed, volume_observed,
      maturity_time_observed,
      state_observed];

    for (var i = 0; i < expected.length; i++) {
      assert.equal(expected[i], observed[i]);
      assert.equal(expected[i], info_observed[i]);
    }
  });

/*
  it("option should be collateralizable", async () => {
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
  it("option should be fee-payable", async () => {
    let token_b = await TokenB.deployed();

    let approve_call = await token_b.approve(option_address, fee, { from: accounts[1] });
    let pay_fee_call = await (
      option
      .methods
      .pay_fee()
      .send({ from: accounts[1] })
    );

    let info_observed = await option.methods.get_info().call();
    let base_balance_observed = await token_b.balanceOf(accounts[0]);
    assert.equal(base_balance_observed, fee);
    assert.equal(info_observed[10], common.state_vals.active);
  });

  it("option should be exercisable from asset", async () => {
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();
    let asset_balance_initial = await token_a.balanceOf(accounts[1]);

    let asset_exercised = web3.utils.toBN(volume).div(web3.utils.toBN(2));
    let base_exercised = (asset_exercised
      .mul(web3.utils.toBN(strike_price_base))
      .div(web3.utils.toBN(strike_price_quote))
    );

    let approve_call = await token_b.approve(option_address, base_exercised.toString(), { from: accounts[1] });
    let exercise_call = await (
      option
      .methods
      .exercise_from_asset(asset_exercised.toString())
      .send({ from: accounts[1] })
    );

    let info_observed = await option.methods.get_info().call();
    let asset_balance_observed = await token_a.balanceOf(accounts[1]);
    assert.equal(asset_balance_observed.sub(asset_balance_initial).toString(), asset_exercised.toString());
    assert.equal(info_observed[10], common.state_vals.exercised);
  });
*/
});

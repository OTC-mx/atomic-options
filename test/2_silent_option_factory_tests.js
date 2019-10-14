const SilentOption = artifacts.require("SilentOption");
const SilentOptionFactory = artifacts.require("SilentOptionFactory");
const TokenA = artifacts.require("TokenA");
const TokenB = artifacts.require("TokenB");

const ethers = require("ethers")
const common = require("./common.js")

contract("SilentOptionFactory test suite", async accounts => {
  // Variables consistent with createOption
  let issuer;
  let buyer;
  let base_addr;
  let asset_addr;
  let fee;
  let strike_price_base_hash;
  let strike_price_quote_hash;
  let volume;
  let maturity_time;
  let expiry_time;

  // Silent option
  let silent_option;
  let silent_option_address;

  // Salt and exchange rate (not known by contract)
  let salt;
  let strike_price_base;
  let strike_price_quote;

  it("should create SilentOption contract", async () => {
    let silent_option_factory = await SilentOptionFactory.deployed();
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();

    salt = ethers.utils.hexZeroPad(ethers.utils.hexlify('0x1738'), 32);
    strike_price_base = 3;
    strike_price_quote = 5;

    let strike_price_base_hex = ethers.utils.hexZeroPad(ethers.utils.hexlify(strike_price_base), 32);
    let strike_price_quote_hex = ethers.utils.hexZeroPad(ethers.utils.hexlify(strike_price_quote), 32);

    // Variables consistent with create_silent_option
    issuer = accounts[0];
    buyer = accounts[1];
    base_addr = token_b.address;
    asset_addr = token_a.address;
    fee = '1' + ('0'.repeat(21));
    strike_price_base_hash = web3.utils.soliditySha3(strike_price_base_hex, salt);
    strike_price_quote_hash = web3.utils.soliditySha3(strike_price_quote_hex, salt);
    volume = '5' + ('0'.repeat(21));
    maturity_time = '0';
    expiry_time = '1577836800';

    console.log('Base Strike Price Hash:', strike_price_base_hash);
    console.log('Quote Strike Price Hash:', strike_price_quote_hash);

    let create_silent_option_call = await (silent_option_factory
      .create_silent_option(issuer, buyer,
        base_addr, asset_addr,
        fee, strike_price_base_hash, strike_price_quote_hash,
        volume,
        maturity_time, expiry_time,
        { from: accounts[0] })
    );
    silent_option_address = create_silent_option_call.logs[0].args[0];
    console.log("Address of Silent Option Created:", silent_option_address);

    assert.equal(Boolean(silent_option_address), true);
  });

  it("should output contract with correct variables", async () => {
    // Variables consistent with create_silent_option
    silent_option = new web3.eth.Contract(SilentOption.abi, silent_option_address);
    let issuer_observed = await silent_option.methods.issuer().call();
    let buyer_observed = await silent_option.methods.buyer().call();
    let base_addr_observed = await silent_option.methods.base_addr().call();
    let asset_addr_observed = await silent_option.methods.asset_addr().call();
    let fee_observed = await silent_option.methods.fee().call();
    let strike_price_base_hash_observed = await silent_option.methods.strike_price_base_hash().call();
    let strike_price_quote_hash_observed = await silent_option.methods.strike_price_quote_hash().call();
    let volume_observed = await silent_option.methods.volume().call();
    let maturity_time_observed = await silent_option.methods.maturity_time().call();
    let expiry_time_observed = await silent_option.methods.expiry_time().call();
    let state_observed = await silent_option.methods.state().call();

    let info_observed = await silent_option.methods.get_info().call();

    let expected = [issuer, buyer, base_addr, asset_addr, fee,
      strike_price_base_hash, strike_price_quote_hash, volume, maturity_time, expiry_time,
      common.state_vals.initialized]

    let observed = [issuer_observed, buyer_observed, base_addr_observed,
      asset_addr_observed, fee_observed, strike_price_base_hash_observed,
      strike_price_quote_hash_observed, volume_observed,
      maturity_time_observed, expiry_time_observed,
      state_observed]

    for (var i = 0; i < expected.length; i++) {
      assert.equal(expected[i], observed[i]);
      assert.equal(expected[i], info_observed[i]);
    }
  });

  it("silent option should be collateralizable", async () => {
    let token_a = await TokenA.deployed();

    let approve_call = await token_a.approve(silent_option_address, volume, { from: accounts[0] });
    let collateralize_call = await (
      silent_option
      .methods
      .collateralize()
      .send({ from: accounts[0] })
    );

    let info_observed = await silent_option.methods.get_info().call();
    let asset_balance_observed = await token_a.balanceOf(silent_option_address);
    assert.equal(asset_balance_observed, volume);
    assert.equal(info_observed[10], common.state_vals.collateralized);
  });

  it("silent option should be fee-payable", async () => {
    let token_b = await TokenB.deployed();

    let approve_call = await token_b.approve(silent_option_address, fee, { from: accounts[1] });
    let pay_fee_call = await (
      silent_option
      .methods
      .pay_fee()
      .send({ from: accounts[1] })
    );

    let info_observed = await silent_option.methods.get_info().call();
    let base_balance_observed = await token_b.balanceOf(accounts[0]);
    assert.equal(base_balance_observed, fee);
    assert.equal(info_observed[10], common.state_vals.active);
  });

  it("silent option should be exercisable from asset", async () => {
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();
    let asset_balance_initial = await token_a.balanceOf(accounts[1]);

    let asset_exercised = web3.utils.toBN(volume).div(web3.utils.toBN(2));
    let base_exercised = (asset_exercised
      .mul(web3.utils.toBN(strike_price_base))
      .div(web3.utils.toBN(strike_price_quote))
    );

    let approve_call = await token_b.approve(silent_option_address, base_exercised.toString(), { from: accounts[1] });

    let exercise_call = await (
      silent_option
      .methods
      .exercise_from_asset(strike_price_base, strike_price_quote, salt, asset_exercised.toString())
      .send({ from: accounts[1] })
    );
    let info_observed = await silent_option.methods.get_info().call();
    let asset_balance_observed = await token_a.balanceOf(accounts[1]);
    assert.equal(asset_balance_observed.sub(asset_balance_initial).toString(), asset_exercised.toString());
    assert.equal(info_observed[10], common.state_vals.exercised);
  });
});

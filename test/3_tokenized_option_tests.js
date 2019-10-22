const TokenizedOption = artifacts.require("TokenizedOption");
const TokenizedOptionFactory = artifacts.require("TokenizedOptionFactory");
const TokenA = artifacts.require("TokenA");
const TokenB = artifacts.require("TokenB");
const PoolToken = artifacts.require("PoolToken");

const ethers = require("ethers");
const common = require("./common.js");

contract("TokenizedOptionFactory/TokenizedOption test suite", async accounts => {
  // Variables consistent with create_option
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

  // TokenizedOption
  let tokenized_option;
  let tokenized_option_address;

  // Tokenized option-specific variables
  let option_claim_addr;
  let collateral_claim_addr;
  let option_claim_supply;
  let collateral_claim_supply;

  let option_claim_name;
  let option_claim_symbol;
  let collateral_claim_name;
  let collateral_claim_symbol;

  it("should create TokenizedOption contract", async () => {
    let tokenized_option_factory = await TokenizedOptionFactory.deployed();
    console.log("Tokenized Option Factory Address", tokenized_option_factory.address);
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();

    // Variables consistent with create_option
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

    collateral_claim_supply = volume;
    option_claim_supply = (web3.utils.toBN(collateral_claim_supply)
                              .mul(web3.utils.toBN(strike_price_base))
                              .div(web3.utils.toBN(strike_price_quote))
                              .toString());
    option_claim_name = "BBB AAA 3/5 Option";
    option_claim_symbol = "BA3/5O";
    collateral_claim_name = "BBB AAA 3/5 Collateral";
    collateral_claim_symbol = "BA3/5C";


    let create_tokenized_option_call = await (tokenized_option_factory
      .create_tokenized_option(issuer, buyer,
        base_addr, asset_addr,
        fee, strike_price_base, strike_price_quote,
        volume,
        maturity_time, expiry_time,
        option_claim_name, option_claim_symbol,
        collateral_claim_name, collateral_claim_symbol,
        { from: accounts[0] })
    );
    tokenized_option_address = create_tokenized_option_call.logs[0].args[0];
    console.log("Address of Option Created:", tokenized_option_address);

    assert.equal(Boolean(tokenized_option_address), true);
  });

  it("should output contract with correct variables", async () => {
    // Variables consistent with create_option
    tokenized_option = new web3.eth.Contract(TokenizedOption.abi, tokenized_option_address);
    let issuer_observed = await tokenized_option.methods.issuer().call();
    let buyer_observed = await tokenized_option.methods.buyer().call();
    let base_addr_observed = await tokenized_option.methods.base_addr().call();
    let asset_addr_observed = await tokenized_option.methods.asset_addr().call();
    let fee_observed = await tokenized_option.methods.fee().call();
    let strike_price_base_observed = await tokenized_option.methods.strike_price_base().call();
    let strike_price_quote_observed = await tokenized_option.methods.strike_price_quote().call();
    let volume_observed = await tokenized_option.methods.volume().call();
    let maturity_time_observed = await tokenized_option.methods.maturity_time().call();
    let expiry_time_observed = await tokenized_option.methods.expiry_time().call();
    let state_observed = await tokenized_option.methods.state().call();

    let info_observed = await tokenized_option.methods.get_info().call();

    let expected = [issuer, buyer, base_addr, asset_addr, fee,
      strike_price_base, strike_price_quote, volume, maturity_time, expiry_time,
      common.state_vals.initialized];

    let observed = [issuer_observed, buyer_observed, base_addr_observed,
      asset_addr_observed, fee_observed, strike_price_base_observed,
      strike_price_quote_observed, volume_observed,
      maturity_time_observed, expiry_time_observed,
      state_observed];

    for (var i = 0; i < expected.length; i++) {
      assert.equal(expected[i], observed[i]);
      assert.equal(expected[i], info_observed[i]);
    }
  });

  it("should output contract with correct tokenized-specific variables", async () => {
    let option_claim_addr_observed = await tokenized_option.methods.option_claim_addr().call();
    let collateral_claim_addr_observed = await tokenized_option.methods.collateral_claim_addr().call();
    let option_claim_supply_observed = await tokenized_option.methods.option_claim_supply().call();
    let collateral_claim_supply_observed = await tokenized_option.methods.collateral_claim_supply().call();

    let token_info_observed = await tokenized_option.methods.get_token_info().call();

    let token_observed = [option_claim_addr_observed, collateral_claim_addr_observed,
      option_claim_supply_observed, collateral_claim_supply_observed];

    let token_expected = [ethers.utils.hexZeroPad('0x0', 20),
      ethers.utils.hexZeroPad('0x0', 20), option_claim_supply, collateral_claim_supply,
      '0', collateral_claim_supply];

    for (var i = 0; i < token_expected.length; i++) {
      if (i < 2) {
        assert.notEqual(ethers.utils.hexZeroPad(token_expected[i], 20), token_observed[i]);
        assert.equal(token_observed[i], token_info_observed[i]);
      } else if (i < 4) {
        assert.equal(token_expected[i], token_observed[i]);
        assert.equal(token_expected[i], token_info_observed[i]);
      } else {
        assert.equal(token_expected[i], token_info_observed[i]);
      }
    }
  });

  it("tokenized option should be collateralizable", async () => {
    let token_a = await TokenA.deployed();

    let approve_call = await token_a.approve(tokenized_option_address, volume, { from: accounts[0] });
    let collateralize_call = await (
      tokenized_option
      .methods
      .collateralize()
      .send({ from: accounts[0] })
    );

    let info_observed = await tokenized_option.methods.get_info().call();
    let asset_balance_observed = await token_a.balanceOf(tokenized_option_address);
    assert.equal(asset_balance_observed, volume)
    assert.equal(info_observed[10], common.state_vals.collateralized)
  });


  it("tokenized option should be fee-payable", async () => {
    let token_b = await TokenB.deployed();

    let approve_call = await token_b.approve(tokenized_option_address, fee, { from: accounts[1] });
    let pay_fee_call = await (
      tokenized_option
      .methods
      .pay_fee()
      .send({ from: accounts[1] })
    );

    let info_observed = await tokenized_option.methods.get_info().call();
    let base_balance_observed = await token_b.balanceOf(accounts[0]);
    assert.equal(base_balance_observed, fee);
    assert.equal(info_observed[10], common.state_vals.active);
  });


  it("tokenized option should be exercisable from asset", async () => {
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();

    let asset_balance_initial = await token_a.balanceOf(accounts[1]);

    let asset_exercised = web3.utils.toBN(volume).div(web3.utils.toBN(2));
    let base_exercised = (asset_exercised
      .mul(web3.utils.toBN(strike_price_base))
      .div(web3.utils.toBN(strike_price_quote))
    );

    let approve_call = await token_b.approve(tokenized_option_address, base_exercised.toString(), { from: accounts[1] });
    let exercise_call = await (
      tokenized_option
      .methods
      .exercise_from_asset(asset_exercised.toString())
      .send({ from: accounts[1] })
    );

    let info_observed = await tokenized_option.methods.get_info().call();
    let asset_balance_observed = await token_a.balanceOf(accounts[1]);
    assert.equal(asset_balance_observed.sub(asset_balance_initial).toString(), asset_exercised.toString());
    assert.equal(info_observed[10], common.state_vals.exercised);
  });
});

const Portfolio = artifacts.require("Portfolio");
const PortfolioFactory = artifacts.require("PortfolioFactory");
const ManagedForward = artifacts.require("ManagedForward");
const ManagedForwardFactory = artifacts.require("ManagedForwardFactory");
const TokenA = artifacts.require("TokenA");
const TokenB = artifacts.require("TokenB");

const ethers = require("ethers");
const common = require("./common.js");

contract("Portfolio[Factory]/ManagedForward[Factory] test suite", async accounts => {
  // Variables consistent with create_forward
  let issuer;
  let buyer;
  let base_addr;
  let asset_addr;
  let strike_price_base;
  let strike_price_quote;
  let volume;
  let maturity_time;

  // Base volume info
  let base_volume;

  // Managed Forward
  let managed_forward;
  let managed_forward_address;

  // Portfolios
  let issuer_portfolio_address;
  let buyer_portfolio_address;

  it("should create Portfolio contracts", async () => {
    let portfolio_factory = await PortfolioFactory.deployed();
    console.log("Portfolio Factory Address:", portfolio_factory.address);
    let managed_forward_factory = await ManagedForwardFactory.deployed();
    console.log("Managed Forward Factory Address:", managed_forward_factory.address);
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();

    base_addr = token_b.address;
    asset_addr = token_a.address;

    let create_issuer_portfolio_call = await (portfolio_factory
      .create_portfolio(
        base_addr, asset_addr, managed_forward_factory.address,
        { from: accounts[0] })
    );
    issuer_portfolio_address = create_issuer_portfolio_call.logs[0].args[0];
    console.log("Address of Issuer Portfolio Created:", issuer_portfolio_address);

    let create_buyer_portfolio_call = await (portfolio_factory
      .create_portfolio(
        base_addr, asset_addr, managed_forward_factory.address,
        { from: accounts[1] })
    );
    buyer_portfolio_address = create_buyer_portfolio_call.logs[0].args[0];
    console.log("Address of Buyer Portfolio Created:", buyer_portfolio_address);

    assert.equal(Boolean(issuer_portfolio_address), true);
    assert.equal(Boolean(buyer_portfolio_address), true);
  });


  it("should create ManagedForward contract", async () => {
    let managed_forward_factory = await ManagedForwardFactory.deployed();
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();

    // Variables consistent with create_forward
    issuer = accounts[0];
    buyer = accounts[1];
    base_addr = token_b.address;
    asset_addr = token_a.address;
    strike_price_base = 3;
    strike_price_quote = 5;
    volume = '5' + ('0'.repeat(21));
    maturity_time = '0';

    base_volume = (web3.utils.toBN(volume)
                              .mul(web3.utils.toBN(strike_price_base))
                              .div(web3.utils.toBN(strike_price_quote))
                              .toString());

    let create_managed_forward_call = await (managed_forward_factory
      .create_managed_forward(issuer, buyer,
        base_addr, asset_addr,
        strike_price_base, strike_price_quote,
        volume,
        maturity_time,
        issuer_portfolio_address, buyer_portfolio_address,
        { from: accounts[0] })
    );
    managed_forward_address = create_managed_forward_call.logs[0].args[0];
    console.log("Address of Managed Forward Created:", managed_forward_address);

    assert.equal(Boolean(managed_forward_address), true);
  });


  it("should output contract with correct variables", async () => {
    // Variables consistent with create_forward
    managed_forward = new web3.eth.Contract(ManagedForward.abi, managed_forward_address);
    let issuer_observed = await managed_forward.methods.issuer().call();
    let buyer_observed = await managed_forward.methods.buyer().call();
    let base_addr_observed = await managed_forward.methods.base_addr().call();
    let asset_addr_observed = await managed_forward.methods.asset_addr().call();
    let strike_price_base_observed = await managed_forward.methods.strike_price_base().call();
    let strike_price_quote_observed = await managed_forward.methods.strike_price_quote().call();
    let volume_observed = await managed_forward.methods.volume().call();
    let maturity_time_observed = await managed_forward.methods.maturity_time().call();
    let state_observed = await managed_forward.methods.state().call();

    let info_observed = await managed_forward.methods.get_info().call();

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

  it("should output contract with correct managed-specific variables", async () => {
    let issuer_portfolio_addr_observed = await managed_forward.methods.issuer_portfolio_addr().call();
    let buyer_portfolio_addr_observed = await managed_forward.methods.buyer_portfolio_addr().call();
    let unmatched_base_volume_observed = await managed_forward.methods.unmatched_base_volume().call();
    let unmatched_asset_volume_observed = await managed_forward.methods.unmatched_asset_volume().call();
    let asset_matched_addr_observed = await managed_forward.methods.asset_matched_addr().call();
    let base_matched_addr_observed = await managed_forward.methods.base_matched_addr().call();

    let portfolio_info_observed = await managed_forward.methods.get_portfolio_info().call();

    let portfolio_observed = [issuer_portfolio_addr_observed, buyer_portfolio_addr_observed,
      unmatched_base_volume_observed, unmatched_asset_volume_observed,
      asset_matched_addr_observed, base_matched_addr_observed];

    let portfolio_expected = [issuer_portfolio_address, buyer_portfolio_address,
      base_volume, volume,
      ethers.utils.hexZeroPad('0x0', 20), ethers.utils.hexZeroPad('0x0', 20)];

    for (var i = 0; i < portfolio_expected.length; i++) {
      assert.equal(portfolio_expected[i], portfolio_observed[i]);
      assert.equal(portfolio_expected[i], portfolio_info_observed[i]);
    }
  });
/*
  it("forward should be collateralizable", async () => {
    let token_a = await TokenA.deployed();

    let approve_call = await token_a.approve(forward_address, volume, { from: accounts[0] });
    let collateralize_call = await (
      forward
      .methods
      .collateralize()
      .send({ from: accounts[0] })
    );

    let info_observed = await forward.methods.get_info().call();
    let asset_balance_observed = await token_a.balanceOf(forward_address);
    assert.equal(asset_balance_observed, volume)
    assert.equal(info_observed[8], common.state_vals.collateralized)
  });

  it("forward should be activatable", async () => {
    let token_b = await TokenB.deployed();

    let approve_call = await token_b.approve(forward_address, base_volume, { from: accounts[1] });
    let pay_fee_call = await (
      forward
      .methods
      .activate()
      .send({ from: accounts[1] })
    );

    let info_observed = await forward.methods.get_info().call();
    let base_balance_observed = await token_b.balanceOf(forward_address);
    assert.equal(base_balance_observed, base_volume);
    assert.equal(info_observed[8], common.state_vals.active);
  });

  it("forward should be settlable", async () => {
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();

    let settle_call = await (
      forward
      .methods
      .settle()
      .send({ from: accounts[1], gas: 180000 })
    );

    let info_observed = await forward.methods.get_info().call();
    let base_balance_observed = await token_b.balanceOf(accounts[0]);
    let asset_balance_observed = await token_a.balanceOf(accounts[1]);
    assert.equal(base_balance_observed, base_volume);
    assert.equal(asset_balance_observed, volume)
    assert.equal(info_observed[8], common.state_vals.expired);
  });
  */
});

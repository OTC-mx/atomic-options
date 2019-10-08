const SilentOption = artifacts.require("silent_option");
const SilentOptionFactory = artifacts.require("silent_option_factory");
const TokenA = artifacts.require("TokenA");
const TokenB = artifacts.require("TokenB");

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

  // Non-template silent option address
  let silent_option_address;

  // Salt and exchange rate (not known by contract)
  let salt;
  let strike_price_base;
  let strike_price_quote;

  it("should update template", async () => {
    let silent_option_template = await SilentOption.deployed();
    let silent_option_factory = await SilentOptionFactory.deployed();
    console.log("Silent Option Factory Address:", silent_option_factory.address);
    
    // Initialize the option factory
    let initialize_call = await (silent_option_factory
      .initializeFactory(silent_option_template.address, { from: accounts[0] }));
    let template_value = await silent_option_factory.template();
    assert.equal(template_value, silent_option_template.address);
  });

  it("should create SilentOption contract", async () => {
    let silent_option_factory = await SilentOptionFactory.deployed();
    let token_a = await TokenA.deployed();
    let token_b = await TokenB.deployed();

    salt = '0x1738';
    strike_price_base = 3;
    strike_price_quote = 5;

    // Variables consistent with createOption
    issuer = accounts[0];
    buyer = accounts[1];
    base_addr = token_b.address;
    asset_addr = token_a.address;
    fee = '1' + ('0'.repeat(21));
    strike_price_base_hash = web3.utils.soliditySha3(strike_price_base, salt);
    strike_price_quote_hash = web3.utils.soliditySha3(strike_price_quote, salt);
    volume = '5' + ('0'.repeat(21));
    maturity_time = '0';
    expiry_time = '1577836800';

    let create_silent_option_call = await (silent_option_factory
      .createSilentOption(issuer, buyer,
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
    // Variables consistent with createOption
    let silent_option = new web3.eth.Contract(SilentOption.abi, silent_option_address);
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

    let info_observed = await silent_option.methods.get_info().call();

    let expected = [issuer, buyer, base_addr, asset_addr, fee,
      strike_price_base_hash, strike_price_quote_hash, volume, maturity_time, expiry_time]

    let observed = [issuer_observed, buyer_observed, base_addr_observed,
      asset_addr_observed, fee_observed, strike_price_base_hash_observed,
      strike_price_quote_hash_observed, volume_observed,
      maturity_time_observed, expiry_time_observed]

    for (var i = 0; i < expected.length; i++) {
      assert.equal(expected[i], observed[i]);
      assert.equal(expected[i], info_observed[i]);
    }
    assert.equal(info_observed[i], 1);
  });

});

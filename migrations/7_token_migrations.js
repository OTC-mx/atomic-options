const TokenA = artifacts.require("TokenA");
const TokenB = artifacts.require("TokenB");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(TokenA);
  deployer.deploy(TokenB, { from: accounts[1] });
};

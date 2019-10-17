const TokenizedOptionFactory = artifacts.require("TokenizedOptionFactory")

module.exports = function(deployer) {
  deployer.deploy(TokenizedOptionFactory);
};

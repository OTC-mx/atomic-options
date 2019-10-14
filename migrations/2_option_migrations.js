const OptionFactory = artifacts.require("OptionFactory");

module.exports = function(deployer) {
  deployer.deploy(OptionFactory);
};
